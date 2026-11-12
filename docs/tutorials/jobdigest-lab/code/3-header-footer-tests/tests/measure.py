"""The measure module: one load, one evaluation, an answer in the contract's lines.

The repository had none, so this is it, to seed/extractors/README.md's "The measure module". A state reached by a form
loads through the caller's `load`, the one navigation; the caller stands on the page before it. This design's
identifiers are element ids, which the module takes, as it takes data-element. The shell, ROW-006's, is the page's header
and footer landmarks outside the marker's section: a control there is no stray, the contract's denominator rule.
"""

SHELL = "header, footer, [role=banner], [role=contentinfo]"

_READ = r"""
({tag, root, elements, content, controls, shell}) => {
  const section = document.getElementById(root);
  if (!section) return [`missing marker ${tag}`];
  const out = [];
  const probe = document.body.appendChild(document.createElement('div'));
  const colour = value => {
    probe.style.color = '';
    probe.style.color = value;
    return getComputedStyle(probe).color;
  };
  const words = value => value.replace(/["']/g, '').trim().toLowerCase();
  const same = (property, cited, painted) => {
    if (property.includes('color')) return colour(cited) === painted;
    if (cited.endsWith('px')) return Math.abs(parseFloat(cited) - parseFloat(painted)) <= 1;
    return words(cited) === words(painted);
  };
  const find = id => id === 'root' ? section
    : id === 'body' ? document.body
    : section.querySelector(`[id="${id}"], [data-element="${id}"]`);
  for (const [id, properties] of Object.entries(elements)) {
    const element = find(id);
    if (!element) { out.push(`missing element ${tag}/${id}`); continue; }
    const style = getComputedStyle(element);
    for (const [property, cited] of Object.entries(properties)) {
      const painted = style.getPropertyValue(property);
      out.push(same(property, cited, painted) ? `ok ${tag}/${id}:${property}`
        : `differs ${tag}/${id}:${property} cited=${cited} painted=${painted}`);
    }
    const box = element.getBoundingClientRect();
    out.push(box.width > 0 && box.height > 0 ? `ok ${tag}/${id}:box`
      : `differs ${tag}/${id}:box cited=non-empty painted=${box.width}x${box.height}`);
  }
  probe.remove();
  for (const text of content)
    if (!section.innerText.includes(text)) out.push(`missing content ${tag} ${text}`);
  const shown = element => element.getClientRects().length > 0;
  const named = element => element.id || element.getAttribute('data-element') || element.tagName.toLowerCase();
  const framed = element => {
    const frame = element.closest(shell);
    return frame !== null && !section.contains(frame);
  };
  const inputs = 'a[href], button, input:not([type=hidden]), select, textarea, [role=button], [role=link]';
  for (const control of document.querySelectorAll(inputs))
    if (shown(control) && !framed(control) && !controls.includes(named(control))) out.push(`stray ${tag} ${named(control)}`);
  for (const element of section.querySelectorAll('[id], [data-element]'))
    if (!(named(element) in elements)) out.push(`stray ${tag} ${named(element)}`);
  return out;
}
"""


def measure(page, tag, literal, load):
    """Load the state `tag` (marker/state) through `load` and answer with the lines for `literal`."""
    navigations, statuses, errors = [], [], []

    def on_navigation(frame):
        if frame == page.main_frame:
            navigations.append(frame.url)

    def on_response(response):
        if response.request.is_navigation_request() and response.frame == page.main_frame:
            statuses.append(response.status)

    def on_console(message):
        if message.type == "error" and not message.location.get("url", "").endswith("/favicon.ico"):
            errors.append(message.text)

    page.on("framenavigated", on_navigation)
    page.on("response", on_response)
    page.on("console", on_console)
    page.on("pageerror", lambda error: errors.append(str(error)))
    load()
    lines = [f"navigations={len(navigations)}"]
    lines += page.evaluate(_READ, {"tag": tag, "shell": SHELL, **literal})
    lines += [f"console error {tag} {error}" for error in errors]
    lines += [f"status {tag} {status}" for status in statuses[-1:]]
    return lines
