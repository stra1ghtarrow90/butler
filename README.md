# keepbutlerintheb.com

Static campaign site for "Keep Butler in the B Team", served with nginx through Docker Compose.

## Run locally

```bash
docker compose up --build
```

Then open `http://localhost:8080`.

## Notes

- The signature counter starts at `27,348`.
- The browser-side counter increments by `1` every `45` seconds.
- Counter state is stored in `localStorage` so refreshes do not reset it in the same browser.
