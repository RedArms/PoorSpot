import json
import os
import hashlib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import uuid4
import uvicorn

app = FastAPI()
DB_FILE = "db.json"

# --- SÉCURITÉ ---
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# --- MODÈLES ---
class UserAuth(BaseModel):
    username: str
    password: str
    attributes: List[str] = []

class User(BaseModel):
    id: str
    name: str
    password_hash: str 
    attributes: List[str] = []
    favorites: List[str] = []  # List of spot IDs
    createdAt: str

class Review(BaseModel):
    id: str
    authorName: str
    ratingRevenue: float
    ratingSecurity: float
    ratingTraffic: float
    attribute: str
    comment: str
    createdAt: str

class Spot(BaseModel):
    id: str
    name: str
    description: str
    latitude: float
    longitude: float
    category: str
    createdAt: str
    createdBy: str
    currentActiveUsers: int
    reviews: List[Review] = []

class Database(BaseModel):
    users: List[User]
    spots: List[Spot]

# --- GESTION DB ---
def get_initial_data():
    return {"users": [], "spots": []}

def load_db() -> Database:
    if not os.path.exists(DB_FILE):
        data = get_initial_data()
        with open(DB_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
        return Database(**data)
    try:
        with open(DB_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Migration: add favorites field to existing users
            for user in data.get("users", []):
                if "favorites" not in user:
                    user["favorites"] = []
            return Database(**data)
    except:
        return Database(**get_initial_data())

def save_db(db: Database):
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(db.model_dump(), f, ensure_ascii=False, indent=4)

# --- ROUTES ---

@app.post("/users/register", response_model=User)
def register(auth: UserAuth):
    db = load_db()
    for u in db.users:
        if u.name.lower() == auth.username.lower():
            raise HTTPException(status_code=400, detail="Pseudo déjà pris")
    
    new_user = User(
        id=str(uuid4()),
        name=auth.username,
        password_hash=hash_password(auth.password),
        attributes=auth.attributes,
        favorites=[],
        createdAt=datetime.now().isoformat()
    )
    db.users.append(new_user)
    save_db(db)
    return new_user

@app.post("/users/login", response_model=User)
def login(auth: UserAuth):
    db = load_db()
    hashed = hash_password(auth.password)
    for u in db.users:
        if u.name.lower() == auth.username.lower() and u.password_hash == hashed:
            return u
    raise HTTPException(status_code=401, detail="Identifiants incorrects")

@app.put("/users/{user_id}/attributes", response_model=User)
def update_attributes(user_id: str, attributes: List[str]):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            u.attributes = attributes
            save_db(db)
            return u
    raise HTTPException(status_code=404, detail="User not found")

# --- FAVORITES ROUTES ---

@app.post("/users/{user_id}/favorites/{spot_id}")
def add_favorite(user_id: str, spot_id: str):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            if spot_id not in u.favorites:
                u.favorites.append(spot_id)
                save_db(db)
            return {"status": "ok", "favorites": u.favorites}
    raise HTTPException(status_code=404, detail="User not found")

@app.delete("/users/{user_id}/favorites/{spot_id}")
def remove_favorite(user_id: str, spot_id: str):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            if spot_id in u.favorites:
                u.favorites.remove(spot_id)
                save_db(db)
            return {"status": "ok", "favorites": u.favorites}
    raise HTTPException(status_code=404, detail="User not found")

@app.get("/users/{user_id}/favorites", response_model=List[str])
def get_favorites(user_id: str):
    db = load_db()
    for u in db.users:
        if u.id == user_id:
            return u.favorites
    raise HTTPException(status_code=404, detail="User not found")

# --- SPOTS ROUTES ---

@app.get("/spots", response_model=List[Spot])
def get_spots():
    return load_db().spots

@app.post("/spots", response_model=Spot)
def create_spot(spot: Spot):
    db = load_db()
    if not spot.id: spot.id = str(uuid4())
    db.spots.append(spot)
    save_db(db)
    return spot

@app.post("/spots/{spot_id}/reviews", response_model=Review)
def add_review(spot_id: str, review: Review):
    db = load_db()
    for s in db.spots:
        if s.id == spot_id:
            s.reviews.insert(0, review)
            save_db(db)
            return review
    raise HTTPException(status_code=404, detail="Spot not found")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)