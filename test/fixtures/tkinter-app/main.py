"""LiveNiro fixture: tkinter, standard library only. A reading list with a spinning progress ring."""
import tkinter as tk

BG, CARD, TEXT, ACCENT = "#17112b", "#241b3d", "#f5f3ff", "#8b5cf6"


def main():
    root = tk.Tk()
    root.title("LiveNiro tkinter Reading List")
    root.geometry("640x420")
    root.configure(bg=BG)

    tk.Label(root, text="Reading list", font=("DejaVu Sans", 20, "bold"), fg=TEXT, bg=BG).pack(anchor="w", padx=24, pady=(18, 8))

    row = tk.Frame(root, bg=BG)
    row.pack(fill="x", padx=24)
    entry = tk.Entry(row, font=("DejaVu Sans", 13), bg=CARD, fg=TEXT, insertbackground=TEXT, relief="flat")
    entry.pack(side="left", fill="x", expand=True, ipady=6)
    books = tk.Listbox(root, font=("DejaVu Sans", 13), bg=CARD, fg=TEXT, relief="flat", height=8,
                       selectbackground=ACCENT, highlightthickness=0)

    def add(_event=None):
        if entry.get().strip():
            books.insert("end", entry.get().strip())
            entry.delete(0, "end")

    tk.Button(row, text="Add", command=add, font=("DejaVu Sans", 12, "bold"), bg=ACCENT, fg=TEXT,
              activebackground="#7c3aed", relief="flat", padx=16).pack(side="left", padx=(10, 0))
    entry.bind("<Return>", add)
    for title in ("The Alchemist", "Clean Code", "Dune"):
        books.insert("end", title)
    books.pack(fill="both", expand=True, padx=24, pady=12)

    ring = tk.Canvas(root, width=40, height=40, bg=BG, highlightthickness=0)
    ring.place(relx=1.0, x=-24, y=18, anchor="ne")
    angle = [0]

    def spin():
        ring.delete("all")
        ring.create_arc(5, 5, 35, 35, start=angle[0], extent=270, style="arc", outline="#ec4899", width=5)
        angle[0] = (angle[0] - 8) % 360
        root.after(30, spin)

    spin()
    entry.focus_set()
    root.mainloop()


if __name__ == "__main__":
    main()
