"""
Lean Factory — main entry point.

Usage:
  python main.py              # launch the game (Phase 2+ requires this)
  python main.py --headless   # run simulation headlessly and print Day-1 metrics
  python main.py --headless --days 5  # run 5 simulated days
"""
import argparse
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("lean_factory")


def _run_headless(days: int) -> None:
    from simulation.factory import Factory
    from persistence.load import has_save, load

    log.info("Lean Factory — Headless Simulation (%d day(s))", days)

    factory = Factory()
    if has_save():
        load(factory)
        log.info("Loaded save — continuing from Day %d", factory.time.day)
    else:
        log.info("New factory — starting from Day 1")

    factory.run_headless(days)

    from persistence.save import save
    save(factory)

    log.info("Day %d Summary", factory.time.day)
    log.info("  Output (last day) : %4d hoverboards", factory.last_day_output)
    log.info("  Plant OEE         : %6.1f%%", factory.live_oee * 100)
    log.info("  Total WIP         : %4d units in-system", factory.live_wip)
    log.info("  FTR (last day)    : %6.1f%%", factory.last_day_ftr * 100)
    log.info("  Improvement Credits: %5d", factory.credits)
    log.info("Station OEE breakdown:")
    for st in factory.stations.values():
        bar_len = int(st.oee * 20)
        bar = "#" * bar_len + "." * (20 - bar_len)
        log.info("  %-22s %s  %4.1f%%", st.id, bar, st.oee * 100)


def _run_game() -> None:
    import pygame
    from config.world_data import OBJECTS, NPCS, PLAYER_SPAWN_TILE
    _INTERACTABLES = OBJECTS + NPCS   # pre-computed once — used every frame
    from simulation.factory import Factory
    from navigation.tilemap import Tilemap
    from navigation.player import Player
    from navigation.camera import TILE_SIZE
    from rendering.factory_renderer import FactoryRenderer
    from ui.hud import HUD
    from ui.inspector import Inspector
    from ui.catalog_panel import CatalogPanel
    from ui.warning_dialog import WarningDialog
    from ui.score_panel import ScorePanel
    from ui.codex_panel import CodexPanel
    from ui.menu import start_screen, pause_menu
    from maturity.mismatch import mismatch_warning
    from persistence.load import has_save, load
    from persistence.save import save
    from config.constants import DB_FILENAME
    from pathlib import Path

    pygame.init()
    pygame.display.set_caption("Lean Factory — NovaGlide Plant 01")
    screen = pygame.display.set_mode((1280, 720))
    clock  = pygame.time.Clock()

    # ── Start screen ──────────────────────────────────────────────────────────
    choice = start_screen(screen, clock, has_save())
    if choice == "quit":
        pygame.quit()
        return

    tilemap  = Tilemap()
    factory  = Factory()
    if choice == "continue" and has_save():
        load(factory)

    player        = Player(PLAYER_SPAWN_TILE, tilemap)
    renderer      = FactoryRenderer(screen, tilemap)
    hud           = HUD(screen)
    inspector     = Inspector(screen)
    catalog_panel = CatalogPanel(screen)
    warning_dlg   = WarningDialog(screen)
    score_panel   = ScorePanel(screen)
    codex_panel   = CodexPanel(screen)

    # Tracks which problem_id is pending CM application after warning
    _pending_cm: dict = {}   # {problem_id, cm_id}

    running          = True
    _last_saved_day  = factory.time.day

    while running:
        real_dt = clock.tick(60) / 1000.0

        # ── Events ────────────────────────────────────────────────────────────
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

            # Codex scroll events
            if codex_panel.is_open:
                codex_panel.handle_event(event)

            # Inspector scroll (mouse wheel / up-down keys handled before other keys)
            if inspector.is_open:
                inspector.handle_event(event)

            # Score panel dismissal (any key)
            if score_panel.is_open:
                score_panel.handle_event(event)
                score_panel.consume_dismiss()
                continue

            # Warning dialog
            if warning_dlg.is_open:
                warning_dlg.handle_event(event)
                result = warning_dlg.consume_result()
                if result == "proceed" and _pending_cm:
                    res = factory.apply_countermeasure(
                        _pending_cm["problem_id"], _pending_cm["cm_id"])
                    if res.get("success"):
                        inspector.close()
                _pending_cm = {}
                continue

            # Catalog panel
            if catalog_panel.is_open:
                catalog_panel.handle_event(event)
                sel = catalog_panel.consume_selection()
                if sel:
                    prob_id = catalog_panel.problem_id
                    catalog_panel.close()
                    prob = factory.problems.get(prob_id or "")
                    zone_m = factory.maturity.zone_maturity(prob.zone_id) if prob else 1.0
                    warn = mismatch_warning(sel.name, sel.tier_int, zone_m)
                    if warn:
                        _pending_cm = {"problem_id": prob_id, "cm_id": sel.id}
                        warning_dlg.show(warn)
                    else:
                        factory.apply_countermeasure(prob_id, sel.id)
                        inspector.close()
                continue

            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    if codex_panel.is_open:
                        codex_panel.close()
                    elif inspector.is_open:
                        inspector.close()
                    else:
                        result = pause_menu(screen, clock)
                        if result == "save":
                            save(factory)
                        elif result == "load":
                            factory = Factory()
                            if has_save():
                                load(factory)
                            inspector.close()
                            inspector._factory = factory
                        elif result == "new_game":
                            Path(DB_FILENAME).unlink(missing_ok=True)
                            factory = Factory()
                            inspector.close()
                            inspector._factory = factory
                        elif result == "quit":
                            running = False

                elif event.key == pygame.K_k:
                    codex_panel.toggle()

                elif event.key in (pygame.K_e, pygame.K_SPACE):
                    target = player.request_interact()
                    if target:
                        inspector.open(target, factory)
                        # Trigger any NPC-gated missions when player talks to this role
                        if target.get("role"):
                            factory.trigger_npc_mission(target["role"])
                    elif inspector.is_open:
                        inspector.close()

                elif event.key == pygame.K_p:
                    factory.time.toggle_pause()

                elif event.key == pygame.K_TAB:
                    factory.time.cycle_speed()

                elif inspector.is_open:
                    if event.key == pygame.K_c:
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "apply_cm":
                            prob = factory.problems.get(action["problem_id"])
                            if prob:
                                station_type = factory.stations[prob.station_id].station_type
                                cms = factory.cm_catalog.applicable_to_station(station_type)
                                catalog_panel.open(action["problem_id"], cms)

                    elif event.key == pygame.K_r:
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "resolve":
                            result = factory.resolve_problem(action["problem_id"])
                            if result:
                                prob = factory.problems[action["problem_id"]]
                                inspector.close()
                                score_panel.show(
                                    prob.name, result["scores"],
                                    result["total"], result["credits_earned"])

                    elif event.key == pygame.K_u:
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "rollback":
                            result = factory.rollback_countermeasure(action["problem_id"])
                            if result:
                                inspector.close()

                    elif event.key == pygame.K_s:
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "standardize":
                            factory.standardize_cm(action["problem_id"])

                    elif event.key == pygame.K_a:
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "adjust":
                            factory.adjust_verification(action["problem_id"])

                    elif event.key == pygame.K_h:
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "hire_specialist":
                            factory.hire_specialist(action["zone_id"])

                    elif event.key in (pygame.K_1, pygame.K_2, pygame.K_3, pygame.K_RETURN):
                        inspector.handle_action_key(event.key)
                        action = inspector.consume_action()
                        if action and action["type"] == "dialogue_choice":
                            prob_id = action["problem_id"]
                            idx     = action["choice_index"]
                            prob    = factory.problems.get(prob_id)
                            if prob and prob.dialogue and prob.dialogue.investigation:
                                choices = prob.dialogue.investigation.choices
                                if idx < len(choices):
                                    session = factory.get_or_create_session(prob_id)
                                    if session and not session.fork_complete:
                                        chosen = choices[idx]
                                        session.record_choice(chosen)
                                        new_concepts = factory.discover(chosen.teaches)
                                        inspector._revealed_choice = {
                                            "problem_id":   prob_id,
                                            "choice":       chosen,
                                            "new_concepts": new_concepts,
                                        }

                        elif action and action["type"] == "five_whys_choice":
                            prob_id = action["problem_id"]
                            idx     = action["choice_index"]
                            prob    = factory.problems.get(prob_id)
                            if prob and prob.dialogue and prob.dialogue.five_whys:
                                session = factory.get_or_create_session(prob_id)
                                if session and not session.five_whys_complete:
                                    step = prob.dialogue.five_whys[session.five_whys_step]
                                    if idx < len(step.choices):
                                        chosen = step.choices[idx]
                                        new_concepts = factory.discover(chosen.teaches)
                                        session.record_five_whys_choice(
                                            chosen, len(prob.dialogue.five_whys))
                                        inspector._revealed_choice = {
                                            "problem_id":   prob_id,
                                            "choice":       chosen,
                                            "new_concepts": new_concepts,
                                        }

                        elif action and action["type"] == "verification_choice":
                            from problems.dialogue import build_verification_fork
                            prob_id = action["problem_id"]
                            idx     = action["choice_index"]
                            prob    = factory.problems.get(prob_id)
                            session = factory.investigation_sessions.get(prob_id) if prob else None
                            if prob and session and not session.verification_complete:
                                cm_rec = factory.active_countermeasures.get(
                                    prob.applied_countermeasure or "")
                                cm = factory.cm_catalog.get(prob.applied_countermeasure or "")
                                if cm and cm_rec and prob.dialogue:
                                    npc = (prob.dialogue.investigation.npc
                                           if prob.dialogue.investigation else "Team Leader")
                                    days = factory.time.day - cm_rec["applied_day"]
                                    vfork = build_verification_fork(
                                        npc, cm.category, cm.name, days)
                                    if idx < len(vfork.choices):
                                        chosen = vfork.choices[idx]
                                        new_concepts = factory.discover(chosen.teaches)
                                        session.record_verification_choice(chosen)
                                        inspector._revealed_choice = {
                                            "problem_id":   prob_id,
                                            "choice":       chosen,
                                            "new_concepts": new_concepts,
                                        }

        # ── Movement ──────────────────────────────────────────────────────────
        if not catalog_panel.is_open and not warning_dlg.is_open and not score_panel.is_open:
            keys = pygame.key.get_pressed()
            dx, dy = 0.0, 0.0
            if keys[pygame.K_w] or keys[pygame.K_UP]:    dy -= 1
            if keys[pygame.K_s] or keys[pygame.K_DOWN]:  dy += 1
            if keys[pygame.K_a] or keys[pygame.K_LEFT]:  dx -= 1
            if keys[pygame.K_d] or keys[pygame.K_RIGHT]: dx += 1
            player.running = keys[pygame.K_LSHIFT] or keys[pygame.K_RSHIFT]
            if dx or dy:
                player.move(dx, dy)

        facing = player.detect_facing(_INTERACTABLES)

        # ── Simulation tick ───────────────────────────────────────────────────
        factory.tick(real_dt)

        # ── Auto-save on in-game day boundary ────────────────────────────────
        if factory.time.day != _last_saved_day:
            save(factory)
            _last_saved_day = factory.time.day

        # ── Render ────────────────────────────────────────────────────────────
        renderer.draw(player, factory)
        hud.draw(factory, player, facing)
        inspector.draw()
        catalog_panel.draw(factory)
        warning_dlg.draw()
        score_panel.draw()
        codex_panel.draw(factory)

        pygame.display.flip()

    save(factory)
    pygame.quit()
    sys.exit(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Lean Factory")
    parser.add_argument("--headless", action="store_true", help="Run without graphics")
    parser.add_argument("--days", type=int, default=1, help="Days to simulate in headless mode")
    args = parser.parse_args()

    if args.headless:
        _run_headless(args.days)
    else:
        _run_game()
