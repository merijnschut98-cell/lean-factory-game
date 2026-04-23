"""
Lean Factory — main entry point.

Usage:
  python main.py              # launch the game (Phase 2+ requires this)
  python main.py --headless   # run simulation headlessly and print Day-1 metrics
  python main.py --headless --days 5  # run 5 simulated days
"""
import argparse
import sys


def _run_headless(days: int) -> None:
    from simulation.factory import Factory
    from persistence.load import has_save, load

    print(f"Lean Factory — Headless Simulation ({days} day(s))")
    print("=" * 52)

    factory = Factory()
    if has_save():
        load(factory)
        print(f"Loaded save — continuing from Day {factory.time.day}")
    else:
        print("New factory — starting from Day 1")

    factory.run_headless(days)

    from persistence.save import save
    save(factory)

    print(f"\n-- Day {factory.time.day} Summary --------------------------")
    print(f"  Output (last day) : {factory.last_day_output:>4} hoverboards")
    print(f"  Plant OEE         : {factory.live_oee * 100:>6.1f}%")
    print(f"  Total WIP         : {factory.live_wip:>4} units in-system")
    print(f"  FTR (last day)    : {factory.last_day_ftr * 100:>6.1f}%")
    print(f"  Improvement Credits: {factory.credits:>5}")
    print()
    print("-- Station OEE breakdown --------------------------")
    for st in factory.stations.values():
        bar_len = int(st.oee * 20)
        bar = "#" * bar_len + "." * (20 - bar_len)
        print(f"  {st.id:<22} {bar}  {st.oee * 100:>4.1f}%")


def _run_game() -> None:
    import pygame
    from config.world_data import OBJECTS, NPCS, PLAYER_SPAWN_TILE
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
    from maturity.mismatch import mismatch_warning
    from persistence.load import has_save, load
    from persistence.save import save

    pygame.init()
    pygame.display.set_caption("Lean Factory — NovaGlide Plant 01")
    screen = pygame.display.set_mode((1280, 720))
    clock  = pygame.time.Clock()

    tilemap   = Tilemap()
    factory   = Factory()
    if has_save():
        load(factory)

    player        = Player(PLAYER_SPAWN_TILE, tilemap)
    renderer      = FactoryRenderer(screen, tilemap)
    hud           = HUD(screen)
    inspector     = Inspector(screen)
    catalog_panel = CatalogPanel(screen)
    warning_dlg   = WarningDialog(screen)
    score_panel   = ScorePanel(screen)

    # Tracks which problem_id is pending CM application after warning
    _pending_cm: dict = {}   # {problem_id, cm_id}

    running    = True
    save_timer = 0.0

    while running:
        real_dt = clock.tick(60) / 1000.0

        # ── Events ────────────────────────────────────────────────────────────
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

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
                    if inspector.is_open:
                        inspector.close()
                    else:
                        running = False

                elif event.key in (pygame.K_e, pygame.K_SPACE):
                    target = player.request_interact()
                    if target:
                        inspector.open(target, factory)
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
                                        factory.discover(chosen.teaches)
                                        inspector._revealed_choice = {
                                            "problem_id": prob_id,
                                            "choice":     chosen,
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

        facing = player.detect_facing(OBJECTS)

        # ── Simulation tick ───────────────────────────────────────────────────
        factory.tick(real_dt)

        # ── Auto-save every 5 real minutes ────────────────────────────────────
        save_timer += real_dt
        if save_timer >= 300.0:
            save(factory)
            save_timer = 0.0

        # ── Render ────────────────────────────────────────────────────────────
        renderer.draw(player, factory)
        hud.draw(factory, player, facing)
        inspector.draw()
        catalog_panel.draw(factory)
        warning_dlg.draw()
        score_panel.draw()

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
