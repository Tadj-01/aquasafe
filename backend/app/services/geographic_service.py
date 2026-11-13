import math
from typing import Optional, Dict, Any, List
import syscli_algeria

# Approximate centroid coordinates for Algeria's 69 Wilayas (latitude, longitude)
WILAYA_CENTROIDS: Dict[str, tuple[float, float]] = {
    "01": (27.8742, -0.2939),   # Adrar
    "02": (36.1652, 1.3345),    # Chlef
    "03": (33.8000, 2.8651),    # Laghouat
    "04": (35.8755, 7.1135),    # Oum El Bouaghi
    "05": (35.5559, 6.1741),    # Batna
    "06": (36.7558, 5.0843),    # Béjaïa
    "07": (34.8504, 5.7280),    # Biskra
    "08": (31.6167, -2.2167),   # Béchar
    "09": (36.4700, 2.8300),    # Blida
    "10": (36.3749, 3.9020),    # Bouira
    "11": (22.7850, 5.5228),    # Tamanghasset
    "12": (35.4042, 8.1242),    # Tébessa
    "13": (34.8783, -1.3150),   # Tlemcen
    "14": (35.3710, 1.3170),    # Tiaret
    "15": (36.7118, 4.0459),    # Tizi Ouzou
    "16": (36.7538, 3.0588),    # Alger
    "17": (34.6728, 3.2630),    # Djelfa
    "18": (36.8205, 5.7667),    # Jijel
    "19": (36.1911, 5.4137),    # Sétif
    "20": (34.8303, 0.1517),    # Saïda
    "21": (36.8762, 6.9092),    # Skikda
    "22": (35.1899, -0.6308),   # Sidi Bel Abbès
    "23": (36.9000, 7.7667),    # Annaba
    "24": (36.4621, 7.4261),    # Guelma
    "25": (36.3650, 6.6147),    # Constantine
    "26": (36.2642, 2.7539),    # Médéa
    "27": (35.9312, 0.0892),    # Mostaganem
    "28": (35.7058, 4.5419),    # M'Sila
    "29": (35.3946, 0.1403),    # Mascara
    "30": (31.9493, 5.3250),    # Ouargla
    "31": (35.6976, -0.6337),   # Oran
    "32": (32.6833, 1.0167),    # El Bayadh
    "33": (28.4467, 9.8700),    # Illizi
    "34": (36.0732, 4.7611),    # Bordj Bou Arréridj
    "35": (36.7599, 3.4772),    # Boumerdes
    "36": (36.7672, 8.3138),    # El Tarf
    "37": (27.6711, -8.1474),   # Tindouf
    "38": (35.6072, 1.8108),    # Tissemsilt
    "39": (33.3683, 6.8675),    # El Oued
    "40": (35.4358, 7.1433),    # Khenchela
    "41": (36.2864, 7.9511),    # Souk Ahras
    "42": (36.5925, 2.4475),    # Tipaza
    "43": (36.4503, 6.2644),    # Mila
    "44": (36.2644, 1.9686),    # Aïn Defla
    "45": (32.7500, -0.3167),   # Naama
    "46": (35.2975, -1.1403),   # Aïn Temouchent
    "47": (32.4909, 3.6736),    # Ghardaïa
    "48": (35.7372, 0.5558),    # Relizane
    "49": (29.2639, 0.2310),    # Timimoun
    "50": (21.3283, 0.9231),    # Bordj Badji Mokhtar
    "51": (34.3333, 5.0667),    # Ouled Djellal
    "52": (30.1333, -2.1667),   # Béni Abbès
    "53": (27.2106, 2.4608),    # In Salah
    "54": (19.5667, 5.7667),    # In Guezzam
    "55": (33.1072, 6.0636),    # Touggourt
    "56": (24.5533, 9.4842),    # Djanet
    "57": (33.9500, 5.9167),    # El M'Ghaier
    "58": (30.5833, 2.8833),    # El Meniaa
    "59": (34.1167, 2.1000),    # Aflou
    "60": (35.3400, 5.3650),    # Barika
    "61": (35.2300, 5.7000),    # El Kantara
    "62": (34.7478, 8.0592),    # Bir El Ater
    "63": (34.2300, -1.3300),   # El Aricha
    "64": (35.2167, 2.3167),    # Ksar Chellala
    "65": (35.4500, 2.9167),    # Aïn Ouessara
    "66": (34.1500, 3.5000),    # Messaad
    "67": (35.8833, 2.7500),    # Ksar El Boukhari
    "68": (35.2158, 4.1758),    # Bou Saâda
    "69": (31.8900, 0.5500),    # El Abiodh Sidi Cheikh
}


def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two points in km."""
    R = 6371.0  # Earth's radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2.0) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2.0) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


class GeographicService:
    @staticmethod
    def validate_coordinates(latitude: float, longitude: float) -> bool:
        """Validate latitude and longitude ranges."""
        if latitude is None or longitude is None:
            return False
        if not (-90.0 <= latitude <= 90.0):
            return False
        if not (-180.0 <= longitude <= 180.0):
            return False
        return True

    @staticmethod
    def is_within_algeria_bounding_box(latitude: float, longitude: float) -> bool:
        """Check if coordinates fall roughly within Algerian territory bounds."""
        # Algeria bounds roughly: Lat 18.0 - 38.0 N, Lon -9.5 - 13.0 E
        return 18.0 <= latitude <= 38.0 and -9.5 <= longitude <= 13.0

    @classmethod
    def lookup_location(
        cls, latitude: float, longitude: float
    ) -> Dict[str, Optional[str]]:
        """
        Identify wilaya and commune for given GPS coordinates.
        Preserves original GPS coordinates, administrative fields are nullable if lookup fails.
        """
        result: Dict[str, Optional[str]] = {
            "wilaya_code": None,
            "wilaya_name": None,
            "commune_code": None,
            "commune_name": None,
        }

        if not cls.validate_coordinates(latitude, longitude):
            return result

        if not cls.is_within_algeria_bounding_box(latitude, longitude):
            return result

        # 1. Find the nearest Wilaya based on centroids
        closest_wilaya_code = None
        min_dist = float("inf")

        for w_code, (w_lat, w_lon) in WILAYA_CENTROIDS.items():
            dist = haversine_distance_km(latitude, longitude, w_lat, w_lon)
            if dist < min_dist:
                min_dist = dist
                closest_wilaya_code = w_code

        if closest_wilaya_code:
            w_obj = syscli_algeria.wilaya(closest_wilaya_code)
            if w_obj:
                result["wilaya_code"] = w_obj.code
                result["wilaya_name"] = w_obj.name_fr

                # 2. Pick a commune for this wilaya from syscli-algeria
                # Communes for this wilaya
                all_communes = syscli_algeria.communes()
                matching_communes = [
                    c for c in all_communes if c.wilaya_code == closest_wilaya_code
                ]

                if matching_communes:
                    # Pick chief town or first commune
                    chief_commune = next(
                        (
                            c
                            for c in matching_communes
                            if c.name_fr.lower() == w_obj.name_fr.lower()
                        ),
                        matching_communes[0],
                    )
                    result["commune_code"] = chief_commune.code
                    result["commune_name"] = chief_commune.name_fr

        return result

    @staticmethod
    def get_all_wilayas() -> List[Dict[str, Any]]:
        """Return list of all 69 Algerian wilayas with ONS codes, French and Arabic names."""
        wilayas = syscli_algeria.wilayas()
        return [
            {
                "code": w.code,
                "name_fr": w.name_fr,
                "name_ar": w.name_ar,
            }
            for w in wilayas
        ]

    @staticmethod
    def get_communes_for_wilaya(wilaya_code: str) -> List[Dict[str, Any]]:
        """Return all communes belonging to a specific wilaya."""
        all_communes = syscli_algeria.communes()
        norm_code = str(wilaya_code).zfill(2)
        communes = [c for c in all_communes if c.wilaya_code == norm_code]
        return [
            {
                "code": c.code,
                "wilaya_code": c.wilaya_code,
                "name_fr": c.name_fr,
                "name_ar": c.name_ar,
            }
            for c in communes
        ]

    @staticmethod
    def search_locations(query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search communes and wilayas supporting French and Arabic spelling variants."""
        results = syscli_algeria.search(query, limit=limit)
        output = []
        for r in results:
            w_code = r.wilaya.code if r.wilaya else r.commune.wilaya_code
            coords = WILAYA_CENTROIDS.get(w_code)
            output.append(
                {
                    "commune_code": r.commune.code,
                    "commune_name_fr": r.commune.name_fr,
                    "commune_name_ar": r.commune.name_ar,
                    "wilaya_code": w_code,
                    "wilaya_name_fr": r.wilaya.name_fr if r.wilaya else "",
                    "wilaya_name_ar": r.wilaya.name_ar if r.wilaya else "",
                    "latitude": coords[0] if coords else None,
                    "longitude": coords[1] if coords else None,
                    "score": r.score,
                }
            )
        return output


geo_service = GeographicService()
