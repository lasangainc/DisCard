import tkinter as tk
from tkinter import ttk
import os
import getpass
from datetime import datetime, timedelta
import threading

root = tk.Tk()
root.title("DisCard")
root.geometry("700x500")

username = getpass.getuser()
path = f"/Users/{username}/Desktop/"
folder_name = "DisCard Cards"
folder_path = os.path.join(path, folder_name)

if not os.path.exists(folder_path):
    os.mkdir(folder_path)

# Fonts
title_font = ("Helvetica Neue", 24, "bold")
tagline_font = ("Helvetica Neue", 12, "italic")
text_font = ("Helvetica Neue", 11)
title_text_font = ("Helvetica Neue", 11, "bold")

# Title and tagline
tk.Label(root, text="DisCard", font=title_font, fg="#333").pack(pady=(10, 0))
tk.Label(root, text="Like Snapchat for your brain", font=tagline_font, fg="#777").pack(pady=(0, 10))

# Add note UI
new_note_frame = tk.Frame(root)
new_note_frame.pack(pady=10)

tk.Label(new_note_frame, text="Title:", font=text_font).grid(row=0, column=0, sticky="e", padx=5)
title_entry = ttk.Entry(new_note_frame, width=30)
title_entry.grid(row=0, column=1, padx=5)

tk.Label(new_note_frame, text="Note:", font=text_font).grid(row=1, column=0, sticky="ne", padx=5)
note_entry = tk.Text(new_note_frame, width=40, height=5, wrap="word", font=text_font, bd=1, relief="solid")
note_entry.grid(row=1, column=1, padx=5)

tk.Label(new_note_frame, text="Disappear in:", font=text_font).grid(row=2, column=0, sticky="e", padx=5)
duration_var = tk.StringVar(value="1 day")
duration_menu = ttk.Combobox(
    new_note_frame,
    textvariable=duration_var,
    values=["1 hour", "1 day", "1 week", "1 month", "Never"],
    state="readonly",
    width=10
)
duration_menu.grid(row=2, column=1, sticky="w", pady=5)

add_button = ttk.Button(new_note_frame, text="Add Note", command=lambda: threading.Thread(target=save_card, args=(title_entry.get(), note_entry.get("1.0", "end"), duration_var.get())).start())
add_button.grid(row=3, column=1, sticky="e", pady=5)

# Scrollable notes area
canvas_frame = tk.Frame(root)
canvas_frame.pack(fill="both", expand=True)

canvas = tk.Canvas(canvas_frame, highlightthickness=0)
scrollbar = ttk.Scrollbar(canvas_frame, orient="vertical", command=canvas.yview)
canvas.configure(yscrollcommand=scrollbar.set)

scrollbar.pack(side="right", fill="y")
canvas.pack(side="left", fill="both", expand=True)

card_frame = tk.Frame(canvas)
canvas.create_window((0, 0), window=card_frame, anchor="nw")

def on_frame_configure(event):
    canvas.configure(scrollregion=canvas.bbox("all"))

card_frame.bind("<Configure>", on_frame_configure)

# Duration parsing
def parse_duration_string(duration_str):
    return {
        "1 hour": timedelta(hours=1),
        "1 day": timedelta(days=1),
        "1 week": timedelta(weeks=1),
        "1 month": timedelta(days=30),
        "Never": timedelta(days=999999)
    }.get(duration_str, timedelta(days=1))

def delete_expired_cards():
    for file in os.listdir(folder_path):
        if not file.endswith(".txt"):
            continue
        try:
            timestamp_str, duration_str = file[:-4].split("_")
            created = datetime.strptime(timestamp_str, "%Y%m%d%H%M%S")
            duration = parse_duration_string(duration_str)
            if datetime.now() > created + duration:
                os.remove(os.path.join(folder_path, file))
        except:
            continue

def load_cards():
    delete_expired_cards()
    for widget in card_frame.winfo_children():
        widget.destroy()
    card_files = sorted([f for f in os.listdir(folder_path) if f.endswith(".txt")], reverse=True)

    if not card_files:
        placeholder = tk.Label(card_frame, text="Write a note!", font=("Helvetica Neue", 16), fg="#999")
        placeholder.grid(row=0, column=0, padx=20, pady=20)
        return

    for i, file in enumerate(card_files):
        with open(os.path.join(folder_path, file), "r") as f:
            content = f.read()
        duration = file.split("_")[-1].replace(".txt", "")
        draw_note(card_frame, content, i // 2, i % 2, file, duration)

def delete_note(filename):
    os.remove(os.path.join(folder_path, filename))
    load_cards()

def update_countdowns():
    for widget in card_frame.winfo_children():
        if hasattr(widget, "countdown"):
            widget.countdown()
    root.after(60000, update_countdowns)

def draw_note(parent, text, row, col, filename, duration):
    frame = tk.Frame(parent)
    frame.grid(row=row, column=col, padx=15, pady=15, sticky="n")

    canvas = tk.Canvas(frame, width=260, height=160, highlightthickness=0)
    canvas.pack()

    canvas.create_rectangle(6, 6, 254, 154, fill="#e0e0e0", outline="", width=0)
    canvas.create_rectangle(0, 0, 248, 148, fill="#FFFACD", outline="", width=0)

    inner_frame = tk.Frame(canvas, bg="#FFFACD")
    canvas.create_window(4, 4, anchor="nw", window=inner_frame, width=240, height=140)

    content_lines = text.split("\n", 2)
    title = content_lines[0] if len(content_lines) > 0 else "Untitled"
    body = content_lines[2] if len(content_lines) > 2 else ""

    tk.Label(inner_frame, text=title, font=title_text_font, bg="#FFFACD", fg="#333", anchor="center").pack(pady=(5, 0))
    tk.Label(inner_frame, text=body, font=text_font, bg="#FFFACD", fg="#333", wraplength=230, justify="left").pack(fill="x", padx=5, pady=2)

    countdown_label = tk.Label(inner_frame, font=("Helvetica Neue", 9), bg="#FFFACD", fg="#666")
    countdown_label.pack(side="bottom", pady=(0, 3))

    def update_timer():
        if duration == "Never":
            countdown_label.config(text="Note will not expire")
        else:
            timestamp_str = filename[:-4].split("_")[0]
            created = datetime.strptime(timestamp_str, "%Y%m%d%H%M%S")
            expiry = created + parse_duration_string(duration)
            remaining = expiry - datetime.now()

            if remaining.days > 0:
                countdown_label.config(text=f"Expires in: {remaining.days} days")
            elif remaining.seconds > 3600:
                countdown_label.config(text=f"Expires in: {remaining.seconds // 3600} hours")
            elif remaining.seconds > 60:
                countdown_label.config(text=f"Expires in: {remaining.seconds // 60} minutes")
            else:
                countdown_label.config(text="Expiring soon")

    frame.countdown = update_timer
    update_timer()

    delete_btn = tk.Canvas(inner_frame, width=15, height=15, bg="#FFFACD", highlightthickness=0)
    delete_btn.create_oval(2, 2, 13, 13, fill="#ff5c5c", outline="")
    delete_btn.place(x=220, y=5)
    delete_btn.bind("<Button-1>", lambda e: delete_note(filename))

def save_card(title, content, duration):
    title = title.strip() or "Untitled"
    content = content.strip()
    if not content:
        return
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    filename = f"{timestamp}_{duration}.txt"
    with open(os.path.join(folder_path, filename), "w") as f:
        f.write(f"{title}\n\n{content}")
    root.after(0, lambda: [
        title_entry.delete(0, tk.END),
        note_entry.delete("1.0", tk.END),
        load_cards()
    ])

root.bind("<Command-Return>", lambda event: save_card(title_entry.get(), note_entry.get("1.0", "end"), duration_var.get()))

load_cards()
update_countdowns()
root.mainloop()
