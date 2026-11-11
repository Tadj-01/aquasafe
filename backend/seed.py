import os
import sys
import argparse
from sqlalchemy.orm import Session

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.security import get_password_hash
from app.models.administrator import Administrator
from app.models.repair_team import RepairTeam


def seed_admin(
    name: str = "Water Authority Admin",
    email: str = "admin@aquasafe.dz",
    password: str = "AquaSafe2026!",
    role: str = "SUPERVISOR",
):
    db: Session = SessionLocal()
    try:
        existing = db.query(Administrator).filter(Administrator.email == email).first()
        if existing:
            print(f"Administrator with email '{email}' already exists (ID: {existing.id}).")
            return existing

        admin = Administrator(
            name=name,
            email=email,
            password_hash=get_password_hash(password),
            role=role,
            is_active=True,
            approval_status="APPROVED",
            signup_source="LOCAL",
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)
        print(f"Successfully created administrator: {email} (ID: {admin.id})")
        return admin
    finally:
        db.close()


def seed_repair_teams():
    db: Session = SessionLocal()
    try:
        teams = [
            {
                "name": "Équipe d'intervention Alger Centre",
                "description": "Intervention rapide réseaux eau potable Alger Centre et environs",
                "phone": "+213 21 00 00 01",
            },
            {
                "name": "Équipe Maintenance Oran Ouest",
                "description": "Réparation canalisations et fuites de voirie",
                "phone": "+213 41 00 00 02",
            },
            {
                "name": "Équipe Constantine Est",
                "description": "Intervention réseau distribution Constantine",
                "phone": "+213 31 00 00 03",
            },
        ]
        created = 0
        for t in teams:
            existing = db.query(RepairTeam).filter(RepairTeam.name == t["name"]).first()
            if not existing:
                team = RepairTeam(
                    name=t["name"],
                    description=t["description"],
                    phone=t["phone"],
                    is_active=True,
                )
                db.add(team)
                created += 1
        db.commit()
        print(f"Seeded {created} repair teams.")
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed database with initial admin and teams.")
    parser.add_argument("--name", default="Water Authority Admin")
    parser.add_argument("--email", default="admin@aquasafe.dz")
    parser.add_argument("--password", default="AquaSafe2026!")
    args = parser.parse_args()

    print("--- AquaSafe Database Seeding ---")
    seed_admin(name=args.name, email=args.email, password=args.password)
    seed_repair_teams()
    print("Database seeding completed.")
