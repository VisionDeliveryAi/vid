# Vendored files

Fetched once at build (v0.9.7.4, 2026-10-14, at the owner's word), from the
addresses the design's runtime itself names (`viewer/page/support.js`,
`REACT_URL` and `REACT_DOM_URL`), and checked against the integrity hashes
it pins (`REACT_SRI`, `REACT_DOM_SRI`): both match.

| file | from | bytes | sha384 (base64) |
|---|---|---|---|
| `react.production.min.js` | https://unpkg.com/react@18.3.1/umd/react.production.min.js | 10751 | DGyLxAyjq0f9SPpVevD6IgztCFlnMF6oW/XQGmfe+IsZ8TqEiDrcHkMLKI6fiB/Z |
| `react-dom.production.min.js` | https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js | 131835 | gTGxhz21lVGYNMcdJOyq01Edg0jhn/c22nsx0kyqP0TxaV5WVdsSH1fSDUf5YJj1 |
| `LICENSE-react` | https://unpkg.com/react@18.3.1/LICENSE | 1086 | — |
| `LICENSE-react-dom` | https://unpkg.com/react-dom@18.3.1/LICENSE | 1086 | — |

Each snapshot places the two scripts inline, before the design's runtime,
so the runtime never fetches them. Their licence (MIT) travels here; each
script also carries its own licence header.
