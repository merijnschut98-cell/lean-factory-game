// One modal at a time, stacked over the 3D view. Opening a modal pauses the
// world input; closing restores it. Esc closes.
import { h } from './dom';

export class Modals {
  private host: HTMLElement;
  private current: HTMLElement | null = null;
  private onClose: (() => void) | null = null;
  onChange: ((open: boolean) => void) | null = null;

  constructor(root: HTMLElement) {
    this.host = h('div.modal-host');
    root.append(this.host);
    window.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.current && !this.current.dataset.locked) this.close();
    });
  }

  get isOpen(): boolean {
    return this.current !== null;
  }

  /** Open a panel. `wide` panels get more room (A3, value stream). */
  open(title: string, body: HTMLElement, opts: { wide?: boolean; locked?: boolean; onClose?: () => void; kicker?: string } = {}): HTMLElement {
    this.close(true);
    const panel = h(`div.modal${opts.wide ? '.wide' : ''}`,
      h('header',
        h('div', opts.kicker ? h('small.kicker', opts.kicker) : null, h('h2', title)),
        opts.locked ? null : h('button.icon-btn', { onclick: () => this.close(), title: 'Close (Esc)', 'aria-label': 'Close' }, '✕'),
      ),
      h('div.modal-body', body),
    );
    if (opts.locked) panel.dataset.locked = '1';
    this.host.replaceChildren(h('div.scrim', { onclick: () => !opts.locked && this.close() }), panel);
    this.host.classList.add('open');
    this.current = panel;
    this.onClose = opts.onClose ?? null;
    this.onChange?.(true);
    return panel;
  }

  /** Swap the body of the open modal (keeps title). */
  setBody(body: HTMLElement): void {
    this.current?.querySelector('.modal-body')?.replaceChildren(body);
  }

  close(silent = false): void {
    if (!this.current) return;
    this.host.classList.remove('open');
    this.host.replaceChildren();
    this.current = null;
    const cb = this.onClose;
    this.onClose = null;
    if (!silent) {
      cb?.();
      this.onChange?.(false);
    }
  }
}
