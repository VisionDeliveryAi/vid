# | row | marker | state | actor | route |
# |---|---|---|---|---|
# | ROW-003 | S01 | saved | anonymous | S01's route, by its form's post |
#
# Provenance: the literal set is read from the spec repository,
# design/screens/S01-save-a-search.html, section s01-saved, and design/tokens.css.
from harness import fresh, fresh_address, open_s01, submit_search
from measure import measure

ROW = "ROW-003"
TAG = "S01/saved"

# tokens.css declares these on body; the section's elements inherit the two that inherit. The paint integrity set says
# each element is drawn. Nothing declares more, so nothing more is compared.
PAINTED = {"color": "#1a1a1a", "font-family": "sans-serif", "visibility": "visible", "opacity": "1"}
LITERAL = {
    "root": "s01-saved",
    "elements": {
        "body": {
            "color": "#1a1a1a",
            "background-color": "#ffffff",
            "font-family": "sans-serif",
            "margin-top": "16px",
            "margin-right": "16px",
            "margin-bottom": "16px",
            "margin-left": "16px",
        },
        "root": PAINTED,
        "saved-search": PAINTED,
        "saved-address": PAINTED,
        "saved-note": PAINTED,
    },
    "content": ["JobDigest", "Check your inbox to confirm"],
    "controls": [],
}


def pins_S01_saved(page, words, address):
    assert page.locator("#saved-search").inner_text().strip() == words, f"{ROW}: #saved-search is not the search saved"
    assert page.locator("#saved-address").inner_text().strip() == address, f"{ROW}: #saved-address is not its address"
    note = page.locator("#saved-note").inner_text().strip()
    assert note == "Check your inbox to confirm", f"{ROW}: #saved-note reads {note!r}"


# ROW-003 promise: S01/saved, as drawn, shows the saved search, its address and the line Check your inbox to confirm;
# ROW-003 promise: authority REQ-001 and the design state S01/saved (the row names "as drawn", so D-003's "below the form"
# ROW-003 promise: is not read as leaving S01/default's controls on the page: the canvas draws none in this state).
# ROW-003 wrong product: shows the canvas's sample values, or the first search saved, or restyles the state, or redraws
# ROW-003 wrong product: the form above the line.
# ROW-003 given: a decoy search and address saved first, then fresh words and a fresh address, neither hard-codable.
# ROW-003 when: S01's real form is submitted, the state's one load. then: every declared property, the content, no
# ROW-003 then: stray control, and each value in its own element, the decoy's in none.
# ROW-003 controls: S01/default answers with its form and no saved state, the case below; the state is absent before the
# ROW-003 controls: save in the target itself.
# ROW-003 technique: the surface instrument, as the row is a surface row; a decoy, as the fault is the right shape with
# ROW-003 technique: the wrong record.
# cases: ROW-003 target=test_ROW_003_S01_saved_as_drawn[chromium] control=test_ROW_003_control_S01_form_reached[chromium]
def test_ROW_003_S01_saved_as_drawn(product_url, page):
    open_s01(page, product_url, ROW)
    submit_search(page, fresh("decoy"), fresh_address())

    words, address = fresh("electrician"), fresh_address()
    open_s01(page, product_url, ROW)
    assert page.locator("#s01-saved").count() == 0, f"{ROW}: the saved state is there before saving"

    lines = measure(page, TAG, LITERAL, lambda: submit_search(page, words, address))

    expected = {"navigations=1", f"status {TAG} 200"}
    oks = [line for line in lines if line.startswith("ok ")]
    wrong = [line for line in lines if not line.startswith("ok ") and line not in expected]
    assert not wrong, f"{ROW}: " + "; ".join(wrong)
    assert expected <= set(lines), f"{ROW}: {lines}"
    assert len(oks) == sum(len(properties) + 1 for properties in LITERAL["elements"].values()), f"{ROW}: {lines}"
    pins_S01_saved(page, words, address)


def test_ROW_003_control_S01_form_reached(product_url, page):
    open_s01(page, product_url, ROW)
    assert page.locator("#s01-default").count() == 1, f"{ROW}: S01 lacks #s01-default"
    assert page.locator("#s01-saved").count() == 0, f"{ROW}: the saved state is there before saving"
