import json
import os
import hashlib
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
from uuid import uuid4
import uvicorn
from datetime import timedelta, datetime # Assurez-vous d'avoir ces imports


DB_FILE = "db.json"

ACHIEVEMENTS_DEF = [
    {"id": "first_step", "name": "Premier Pas", "desc": "Mendier pour la première fois", "points": 10, "icon": "footprint"},
    {"id": "explorer_3", "name": "Petit Explorateur", "desc": "Mendier à 3 endroits différents", "points": 50, "icon": "compass"},
    {"id": "explorer_10", "name": "Grand Voyageur", "desc": "Mendier à 10 endroits différents", "points": 200, "icon": "map"},
    {"id": "time_1h", "name": "Débutant", "desc": "Cumuler 1 heure de mendicité", "points": 20, "icon": "hourglass_bottom"},
    {"id": "time_10h", "name": "Professionnel", "desc": "Cumuler 10 heures de mendicité", "points": 150, "icon": "hourglass_top"},
    {"id": "time_24h", "name": "Acharné", "desc": "Cumuler 24 heures de mendicité", "points": 500, "icon": "fire"},
    {"id": "night_owl", "name": "Oiseau de Nuit", "desc": "Mendier entre 2h et 5h du matin", "points": 100, "icon": "bedtime"},
    {"id": "biz_man", "name": "Business Man", "desc": "Visiter 3 spots de type Business", "points": 75, "icon": "business_center"},
    {"id": "tourist", "name": "Touriste", "desc": "Visiter 3 spots de type Tourisme", "points": 75, "icon": "camera_alt"},
]

# --- ÉTAT VOLATILE (RAM) ---
# Format: { "spot_id": { "userId": "...", "userName": "..." } }
active_occupations: Dict[str, dict] = {}

# --- GESTION DB (Helpers) ---
def load_db_data():
    if not os.path.exists(DB_FILE):
        return {"users": [], "spots": []}
    try:
        with open(DB_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except:
        return {"users": [], "spots": []}

def save_db_data(data):
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

# --- LIFESPAN (Démarrage & Arrêt) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Démarrage : On pourrait nettoyer les sessions fantômes ici si besoin
    print("--- SERVER START ---")
    yield
    # Arrêt (Shutdown) : On clôture toutes les sessions en cours
    print("--- SERVER SHUTDOWN : Clôture des sessions ---")
    if active_occupations:
        data = load_db_data()
        users = data.get("users", [])
        
        # Pour chaque occupation active
        for spot_id, occupant_info in active_occupations.items():
            user_id = occupant_info["userId"]
            # Trouver l'user
            user = next((u for u in users if u["id"] == user_id), None)
            if user and "history" in user and user["history"]:
                # On suppose que le dernier log est celui en cours
                last_log = user["history"][0]
                if last_log.get("spotId") == spot_id and not last_log.get("durationSeconds"):
                    start_time = datetime.fromisoformat(last_log["timestamp"])
                    duration = (datetime.now() - start_time).total_seconds()
                    last_log["durationSeconds"] = int(duration)
                    print(f"Session close pour {user['name']} : {int(duration)}s")
        
        save_db_data(data)
        active_occupations.clear()

app = FastAPI(lifespan=lifespan)

# --- SÉCURITÉ ---
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# --- MODÈLES ---
class UserAuth(BaseModel):
    username: str
    password: str
    attributes: List[str] = []

class CheckInLog(BaseModel):
    spotId: str
    spotName: str
    timestamp: str
    durationSeconds: Optional[int] = 0

class User(BaseModel):
    id: str
    name: str
    password_hash: str 
    attributes: List[str] = []
    favorites: List[str] = []
    history: List[CheckInLog] = [] 
    createdAt: str
    points: int = 0
    achievements: List[str] = [] # Liste des IDs débloqués

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

# --- HELPER LOAD MODEL ---
def load_db() -> Database:
    data = load_db_data()
    # Migrations
    for user in data.get("users", []):
        if "favorites" not in user: user["favorites"] = []
        if "history" not in user: user["history"] = []
    return Database(**data)

def save_db(db: Database):
    save_db_data(db.model_dump())

# --- LOGIQUE DE VÉRIFICATION DES SUCCÈS ---
def check_new_achievements(user: User, db: Database, current_spot: Spot = None):
    new_unlocks = []
    
    # Helper pour savoir si déjà débloqué
    def has(aid): return aid in user.achievements

    # 1. First Step
    if user.history and not has("first_step"):
        new_unlocks.append("first_step")

    # Données agrégées
    distinct_spot_ids = set(log.spotId for log in user.history)
    total_seconds = sum(log.durationSeconds for log in user.history if log.durationSeconds)
    
    # Spots par catégorie
    spots_by_cat = {}
    for log in user.history:
        # On doit retrouver le spot dans la db pour connaitre sa categorie (lourd mais ok pour proto)
        s = next((x for x in db.spots if x.id == log.spotId), None)
        if s:
            spots_by_cat.setdefault(s.category, set()).add(s.id)

    # 2. Explorer
    if len(distinct_spot_ids) >= 3 and not has("explorer_3"): new_unlocks.append("explorer_3")
    if len(distinct_spot_ids) >= 10 and not has("explorer_10"): new_unlocks.append("explorer_10")

    # 3. Time
    if total_seconds >= 3600 and not has("time_1h"): new_unlocks.append("time_1h")
    if total_seconds >= 36000 and not has("time_10h"): new_unlocks.append("time_10h")
    if total_seconds >= 86400 and not has("time_24h"): new_unlocks.append("time_24h")

    # 4. Categories
    if len(spots_by_cat.get("Business", [])) >= 3 and not has("biz_man"): new_unlocks.append("biz_man")
    if len(spots_by_cat.get("Tourisme", [])) >= 3 and not has("tourist"): new_unlocks.append("tourist")

    # 5. Contextuel (Dernier log)
    if user.history:
        last = user.history[0]
        dt = datetime.fromisoformat(last.timestamp)
        # Si c'est entre 2h et 5h du mat
        if 2 <= dt.hour < 5 and not has("night_owl"):
             new_unlocks.append("night_owl")

    # Appliquer les changements
    result_objects = []
    for aid in new_unlocks:
        defi = next((d for d in ACHIEVEMENTS_DEF if d["id"] == aid), None)
        if defi:
            user.achievements.append(aid)
            user.points += defi["points"]
            result_objects.append(defi)
    
    return result_objects
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
        history=[],
        createdAt=datetime.now().isoformat()
    )
    db.users.append(new_user)
    save_db(db)
    return new_user

@app.get("/users/top")
def get_top_users(period: str = "forever", sort_by: str = "time"):
    """
    sort_by: 'time' (defaut) ou 'points'
    """
    db = load_db()
    
    # Si tri par points, on ignore la période (les points sont toujours globaux)
    if sort_by == "points":
        leaderboard = []
        for user in db.users:
            if user.points > 0:
                leaderboard.append({
                    "userId": user.id,
                    "name": user.name,
                    "score": user.points, # On renvoie 'score' générique
                    "achievements_count": len(user.achievements)
                })
        leaderboard.sort(key=lambda x: x["score"], reverse=True)
        return leaderboard[:50]

    # Sinon logique temporelle classique...
    now = datetime.now()
    cutoff = None
    if period == "daily": cutoff = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == "weekly": cutoff = now - timedelta(days=7)
    elif period == "monthly": cutoff = now - timedelta(days=30)

    leaderboard = []
    for user in db.users:
        total_seconds = 0
        for log in user.history:
            if log.durationSeconds and log.durationSeconds > 0:
                log_date = datetime.fromisoformat(log.timestamp)
                if cutoff is None or log_date >= cutoff:
                    total_seconds += log.durationSeconds
        
        if total_seconds > 0:
            leaderboard.append({
                "userId": user.id,
                "name": user.name,
                "score": total_seconds, # On utilise le même champ 'score' pour simplifier le front
                "attributes": user.attributes
            })

    leaderboard.sort(key=lambda x: x["score"], reverse=True)
    return leaderboard[:50]

# --- ROUTE INFO ACHIEVEMENTS ---
@app.get("/achievements/list")
def get_achievements_list():
    return ACHIEVEMENTS_DEF

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

# --- ROUTES OCCUPATION ---

@app.get("/occupations")
def get_occupations():
    return active_occupations

@app.post("/spots/{spot_id}/occupy")
def occupy_spot(spot_id: str, user_id: str):
    # 1. Vérifier si le spot visé est déjà occupé par un autre
    current_occupant_info = active_occupations.get(spot_id)
    if current_occupant_info and current_occupant_info["userId"] != user_id:
        raise HTTPException(status_code=409, detail="Spot déjà occupé")

    # Charger la DB maintenant car on en a besoin pour clore l'historique précédent
    db = load_db()
    user = next((u for u in db.users if u.id == user_id), None)
    spot = next((s for s in db.spots if s.id == spot_id), None)
    
    if not user or not spot:
        raise HTTPException(status_code=404, detail="User ou Spot introuvable")

    # 2. AUTO-RELEASE : Gestion du changement de spot
    # On cherche si l'user est déjà quelque part
    for s_id, info in list(active_occupations.items()):
        if info["userId"] == user_id and s_id != spot_id:
            # --- CORRECTION ICI : On ferme l'historique précédent dans la DB ---
            if user.history:
                # On cherche le log ouvert (durationSeconds == 0) correspondant au spot s_id
                # On prend le premier trouvé (le plus récent)
                for log in user.history:
                    if log.spotId == s_id and (not log.durationSeconds):
                        start_time = datetime.fromisoformat(log.timestamp)
                        duration = (datetime.now() - start_time).total_seconds()
                        log.durationSeconds = int(duration)
                        break # On a trouvé et fermé, on sort de la boucle user.history
            
            # On supprime de la RAM
            del active_occupations[s_id]

    # 3. Créer la nouvelle occupation
    active_occupations[spot_id] = {
        "userId": user.id,
        "userName": user.name
    }

    # 4. Créer le nouveau log
    new_log = CheckInLog(
        spotId=spot.id,
        spotName=spot.name,
        timestamp=datetime.now().isoformat(),
        durationSeconds=0
    )
    user.history.insert(0, new_log)
    
    save_db(db)

    return {"status": "occupied", "history_entry": new_log}


@app.post("/spots/{spot_id}/release")
def release_spot(spot_id: str, user_id: str):
    # ... (Logique existante de vérification et suppression RAM) ...
    current_occupant_info = active_occupations.get(spot_id)
    if current_occupant_info:
        if current_occupant_info["userId"] != user_id:
            raise HTTPException(status_code=403, detail="Vous n'occupez pas ce spot")
        del active_occupations[spot_id]

    # Update DB history & Calc Stats
    db = load_db()
    user = next((u for u in db.users if u.id == user_id), None)
    spot = next((s for s in db.spots if s.id == spot_id), None)

    duration = 0
    new_badges = []

    if user and user.history:
        last_log = user.history[0]
        if last_log.spotId == spot_id and (not last_log.durationSeconds):
            start_time = datetime.fromisoformat(last_log.timestamp)
            duration = int((datetime.now() - start_time).total_seconds())
            last_log.durationSeconds = duration
            
            # --- CHECK ACHIEVEMENTS ---
            new_badges = check_new_achievements(user, db, spot)
            
            save_db(db)

    return {
        "status": "released", 
        "duration": duration, 
        "new_achievements": new_badges, # On renvoie les badges débloqués pour l'UI
        "total_points": user.points if user else 0
    }# --- FAVORIS & SPOTS ---

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