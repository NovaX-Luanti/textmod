# TextMod for Luanti / Minetest

**TextMod** is a lightweight mod that lets you spawn floating text anywhere in your world using the `/text` command.

It's perfect for:
- Spawn messages
- Info signs
- Waypoints
- Custom map decorations

💡 **Original idea by [nono]**

---

## ✨ Features

- `/text` command to spawn floating text
- Accepts **HEX color codes** (e.g. `#FF0000`)
- Supports **multi-line text** using `\n`
- Optionally configurable max number of texts and range via `settings.conf`
- `/remove_text` command to delete text by ID or position
- No dependencies required

---

## 🧪 Usage Examples

```bash
/text #00FF00 "Hello above me!"
/text 0 10 0 #FF0000 "Text at coordinates"
/remove_text 1
/remove_text 0 10 0
```

---

## ⚙️ Configuration (`settings.conf`)

```ini
textmod_max_texts = 100         # Max number of texts allowed
textmod_default_range = 200     # Default visibility range
```

---

## 🔥 Known Limitations

Due to engine restrictions, **colored nametags on entities** are not reliably supported in all clients. The `color` is stored and parsed correctly, but may appear as white depending on the Minetest or Luanti version.

---

## 📄 License

MIT License — © 2025 NovaX  
Idea by **nono**

---

## ❤️ Credits

- Idea: **nono**  
- Development: **NovaX**
