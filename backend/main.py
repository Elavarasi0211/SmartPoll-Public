import os
import sqlite3
import uuid
import pickle
import base64
import secrets
import shutil
from pathlib import Path

import cv2
import numpy as np
import smtplib
import random
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from insightface.app import FaceAnalysis


# ============================================================
# PATHS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BASE_DIR.parent

DB_PATH = BASE_DIR / "smartpoll.db"
DATASET_DIR = PROJECT_DIR / "face_dataset"

# Visual Cryptography share storage
SHARES_DIR = BASE_DIR / "vote_shares"

SHARES_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# APP
# ============================================================
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM_EMAIL = os.getenv("SMTP_FROM_EMAIL", SMTP_USERNAME)


OTP_EXPIRY_MINUTES = 5
OTP_MAX_ATTEMPTS = 5

app = FastAPI(
    title="SmartPoll API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# FACE ML MODEL
# ============================================================

print()
print("Loading InsightFace buffalo_l...")

face_app = FaceAnalysis(
    name="buffalo_l",
    providers=["CPUExecutionProvider"],
)

face_app.prepare(
    ctx_id=0,
    det_size=(640, 640)
)

DEFAULT_THRESHOLD = 0.50

FACE_THRESHOLD = float(
    os.getenv(
        "SMARTPOLL_FACE_THRESHOLD",
        DEFAULT_THRESHOLD
    )
)

print("InsightFace loaded successfully.")
print("Face threshold:", FACE_THRESHOLD)


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():

    connection = sqlite3.connect(
        DB_PATH,
        check_same_thread=False
    )

    connection.row_factory = sqlite3.Row

    return connection


# ============================================================
# DATABASE INITIALIZATION
# ============================================================

def initialize_database():

    connection = get_connection()

    try:

        # ----------------------------------------------------
        # VOTERS TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS voters (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                voter_id TEXT UNIQUE NOT NULL,

                name TEXT NOT NULL,

                phone TEXT,

                email TEXT,

                district TEXT,

                taluk TEXT,

                block TEXT,

                panchayat TEXT,

                ward TEXT,

                booth TEXT,

                face_status TEXT DEFAULT 'Registered',

                voted INTEGER DEFAULT 0

            )
            """
        )

        # ----------------------------------------------------
        # CANDIDATES TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS candidates (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                candidate_name TEXT NOT NULL,

                party_name TEXT NOT NULL,

                district TEXT,

                taluk TEXT,

                block TEXT,

                panchayat TEXT,

                ward TEXT,

                booth TEXT,

                symbol TEXT

            )
            """
        )

        # ----------------------------------------------------
        # ADMINS TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS admins (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                admin_id TEXT UNIQUE NOT NULL,

                username TEXT UNIQUE NOT NULL,

                password TEXT NOT NULL,

                name TEXT NOT NULL,

                face_status TEXT DEFAULT 'Registered'

            )
            """
        )

        # ----------------------------------------------------
        # VERIFICATION LOGS TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS verification_logs (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                voter_id TEXT,

                verification_type TEXT,

                similarity REAL,

                threshold REAL,

                result TEXT,

                timestamp DATETIME
                    DEFAULT CURRENT_TIMESTAMP

            )
            """
        )

        # ----------------------------------------------------
        # DATABASE MIGRATION
        # ----------------------------------------------------

        verification_columns = connection.execute(
            """
            PRAGMA table_info(verification_logs)
            """
        ).fetchall()

        verification_column_names = {
            column["name"]
            for column in verification_columns
        }

        if "verification_type" not in verification_column_names:

            connection.execute(
                """
                ALTER TABLE verification_logs
                ADD COLUMN verification_type TEXT
                """
            )

            print(
                "verification_type column added "
                "to verification_logs."
            )

        if "similarity" not in verification_column_names:

            connection.execute(
                """
                ALTER TABLE verification_logs
                ADD COLUMN similarity REAL
                """
            )

            print(
                "similarity column added "
                "to verification_logs."
            )

        if "threshold" not in verification_column_names:

            connection.execute(
                """
                ALTER TABLE verification_logs
                ADD COLUMN threshold REAL
                """
            )

            print(
                "threshold column added "
                "to verification_logs."
            )

        if "result" not in verification_column_names:

            connection.execute(
                """
                ALTER TABLE verification_logs
                ADD COLUMN result TEXT
                """
            )

            print(
                "result column added "
                "to verification_logs."
                )
        # ----------------------------------------------------
        # ADMIN PROFILE MIGRATION
        # ----------------------------------------------------

        admin_columns = connection.execute(
            """
            PRAGMA table_info(admins)
            """
        ).fetchall()

        admin_column_names = {
            column["name"]
            for column in admin_columns
        }

        if "email" not in admin_column_names:

            connection.execute(
                """
                ALTER TABLE admins
                ADD COLUMN email TEXT
                """
            )

            print(
                "email column added to admins."
            )

        if "phone" not in admin_column_names:

            connection.execute(
                """
                ALTER TABLE admins
                ADD COLUMN phone TEXT
                """
            )

            print(
                "phone column added to admins."
            )
        # ----------------------------------------------------
        # VOTER EMAIL MIGRATION
        # ----------------------------------------------------

        voter_columns = connection.execute(
            """
            PRAGMA table_info(voters)
            """
        ).fetchall()

        voter_column_names = {
            column["name"]
            for column in voter_columns
        }

        if "email" not in voter_column_names:

            connection.execute(
                """
                ALTER TABLE voters
                ADD COLUMN email TEXT
                """
            )

            print(
                "email column added to voters."
            )

        # ----------------------------------------------------
        # EMAIL OTP TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS email_otps (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                voter_id TEXT NOT NULL,

                email TEXT NOT NULL,

                otp_hash TEXT NOT NULL,

                created_at DATETIME
                    DEFAULT CURRENT_TIMESTAMP,

                expires_at DATETIME NOT NULL,

                attempts INTEGER DEFAULT 0,

                used INTEGER DEFAULT 0

            )
            """
        )

        # ----------------------------------------------------
        # VOTES TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS votes (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                voter_id TEXT NOT NULL,

                candidate_id INTEGER NOT NULL,

                reference_id TEXT,

                timestamp DATETIME
                    DEFAULT CURRENT_TIMESTAMP

            )
            """
        )

        # ----------------------------------------------------
        # IMPORTANT DATABASE COMPATIBILITY
        # ----------------------------------------------------

        vote_columns = connection.execute(
            """
            PRAGMA table_info(votes)
            """
        ).fetchall()

        vote_column_names = {
            column["name"]
            for column in vote_columns
        }

        if "created_at" in vote_column_names:

            print(
                "Votes table time column: created_at"
            )

        elif "timestamp" in vote_column_names:

            print(
                "Votes table time column: timestamp"
            )

        else:

            print(
                "Warning: No vote time column found."
            )

        # ----------------------------------------------------
        # VISUAL CRYPTOGRAPHY SHARES TABLE
        # ----------------------------------------------------

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS vote_shares (

                id INTEGER PRIMARY KEY AUTOINCREMENT,

                vote_id INTEGER UNIQUE NOT NULL,

                voter_id TEXT NOT NULL,

                reference_id TEXT,

                candidate_id INTEGER NOT NULL,

                share1_path TEXT NOT NULL,

                share2_path TEXT NOT NULL,

                created_at DATETIME
                    DEFAULT CURRENT_TIMESTAMP

            )
            """
        )

        # ----------------------------------------------------
        # DEFAULT ADMIN ACCOUNT
        # ----------------------------------------------------

        admin = connection.execute(
            """
            SELECT *
            FROM admins
            WHERE admin_id = ?
            """,
            ("ADMIN001",)
        ).fetchone()

        if admin is None:

            connection.execute(
                """
                INSERT INTO admins
                (
                    admin_id,
                    username,
                    password,
                    name,
                    face_status
                )
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    "ADMIN001",
                    "admin",
                    "admin123",
                    "SmartPoll Admin",
                    "Registered"
                )
            )

            print(
                "Default admin account created."
            )

        connection.commit()

        print(
            "Database initialized successfully."
        )

    except Exception as error:

        connection.rollback()

        print(
            "Database initialization error:",
            error
        )

        raise

    finally:

        connection.close()


initialize_database()


# ============================================================
# VISUAL CRYPTOGRAPHY CONFIGURATION
# ============================================================

VC_IMAGE_SIZE = 64

# Magic value used to identify a SmartPoll VC image.
VC_MAGIC = 0x53504F4C


# ============================================================
# VISUAL CRYPTOGRAPHY HELPER FUNCTIONS
# ============================================================

def _integer_to_bits(
    value,
    bit_count=32
):

    value = int(value)

    bits = [
        (value >> bit)
        & 1
        for bit in range(
            bit_count - 1,
            -1,
            -1
        )
    ]

    return bits


def _bits_to_integer(
    bits
):

    value = 0

    for bit in bits:

        value = (
            value << 1
        ) | int(bit)

    return value


def create_vote_binary_image(
    candidate_id
):

    total_pixels = (
        VC_IMAGE_SIZE *
        VC_IMAGE_SIZE
    )

    source_bits = np.zeros(
        total_pixels,
        dtype=np.uint8
    )

    # --------------------------------------------------------
    # Encode SmartPoll magic value.
    # --------------------------------------------------------

    magic_bits = _integer_to_bits(
        VC_MAGIC,
        32
    )

    # --------------------------------------------------------
    # Encode actual candidate ID.
    # --------------------------------------------------------

    candidate_bits = _integer_to_bits(
        candidate_id,
        32
    )

    encoded_bits = (
        magic_bits +
        candidate_bits
    )

    source_bits[
        :len(encoded_bits)
    ] = np.asarray(
        encoded_bits,
        dtype=np.uint8
    )

    source_image = (
        source_bits.reshape(
            VC_IMAGE_SIZE,
            VC_IMAGE_SIZE
        )
        * 255
    ).astype(
        np.uint8
    )

    return source_image


def generate_visual_cryptography_shares(
    candidate_id
):

    source_image = (
        create_vote_binary_image(
            candidate_id
        )
    )

    total_pixels = (
        VC_IMAGE_SIZE *
        VC_IMAGE_SIZE
    )

    # --------------------------------------------------------
    # Generate cryptographically random Share 1.
    # --------------------------------------------------------

    random_bytes = secrets.token_bytes(
        total_pixels // 8
    )

    share1_bits = np.unpackbits(
        np.frombuffer(
            random_bytes,
            dtype=np.uint8
        )
    )[:total_pixels]

    source_bits = (
        source_image.flatten()
        // 255
    ).astype(
        np.uint8
    )

    # --------------------------------------------------------
    # Share 2 = Share 1 XOR original vote.
    # --------------------------------------------------------

    share2_bits = (
        share1_bits ^
        source_bits
    )

    share1_image = (
        share1_bits.reshape(
            VC_IMAGE_SIZE,
            VC_IMAGE_SIZE
        )
        * 255
    ).astype(
        np.uint8
    )

    share2_image = (
        share2_bits.reshape(
            VC_IMAGE_SIZE,
            VC_IMAGE_SIZE
        )
        * 255
    ).astype(
        np.uint8
    )

    return (
        share1_image,
        share2_image
    )


def save_share_image(
    image,
    file_path
):

    success, encoded = cv2.imencode(
        ".png",
        image
    )

    if not success:

        raise RuntimeError(
            "Unable to encode visual cryptography share."
        )

    file_path.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    file_path.write_bytes(
        encoded.tobytes()
    )


def load_share_image(
    file_path
):

    if not file_path.exists():

        raise FileNotFoundError(
            f"Share file not found: {file_path}"
        )

    image_bytes = (
        file_path.read_bytes()
    )

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_GRAYSCALE
    )

    if image is None:

        raise ValueError(
            f"Unable to read share: {file_path}"
        )

    if (
        image.shape[0]
        != VC_IMAGE_SIZE
        or
        image.shape[1]
        != VC_IMAGE_SIZE
    ):

        raise ValueError(
            "Invalid visual cryptography share size."
        )

    return image


def combine_share_images(
    share1,
    share2
):

    if share1.shape != share2.shape:

        raise ValueError(
            "Share dimensions do not match."
        )

    share1_bits = (
        share1 >= 128
    ).astype(
        np.uint8
    )

    share2_bits = (
        share2 >= 128
    ).astype(
        np.uint8
    )

    combined_bits = (
        share1_bits ^
        share2_bits
    )

    combined_image = (
        combined_bits *
        255
    ).astype(
        np.uint8
    )

    return combined_image


def decode_candidate_id(
    combined_image
):

    combined_bits = (
        combined_image.flatten()
        // 255
    ).astype(
        np.uint8
    )

    if len(combined_bits) < 64:

        raise ValueError(
            "Combined image is too small."
        )

    magic_bits = (
        combined_bits[:32]
    )

    candidate_bits = (
        combined_bits[32:64]
    )

    decoded_magic = (
        _bits_to_integer(
            magic_bits
        )
    )

    if decoded_magic != VC_MAGIC:

        raise ValueError(
            "Invalid SmartPoll visual cryptography shares."
        )

    candidate_id = (
        _bits_to_integer(
            candidate_bits
        )
    )

    return int(
        candidate_id
    )


def image_to_base64(
    image_path
):

    image_bytes = (
        image_path.read_bytes()
    )

    encoded = base64.b64encode(
        image_bytes
    ).decode(
        "utf-8"
    )

    return (
        "data:image/png;base64,"
        +
        encoded
    )


def relative_share_path(
    file_path
):

    try:

        return str(
            file_path.relative_to(
                BASE_DIR
            )
        )

    except ValueError:

        return str(
            file_path
        )


# ============================================================
# GET LATEST VOTE FOR EACH REGISTERED VOTER
# ============================================================

def get_latest_votes_for_registered_voters(
    connection
):

    voters = connection.execute(
        """
        SELECT
            voter_id,
            name
        FROM voters
        ORDER BY id ASC
        """
    ).fetchall()

    latest_votes = []

    for voter in voters:

        latest_vote = connection.execute(
            """
            SELECT
                v.id,
                v.voter_id,
                v.candidate_id,
                v.reference_id,
                c.candidate_name,
                c.party_name,
                c.symbol
            FROM votes v
            LEFT JOIN candidates c
                ON v.candidate_id = c.id
            WHERE v.voter_id = ?
            ORDER BY v.id DESC
            LIMIT 1
            """,
            (
                voter["voter_id"],
            )
        ).fetchone()

        if latest_vote is None:

            continue

        latest_votes.append(
            {
                "vote_id":
                latest_vote["id"],

                "voter_id":
                latest_vote["voter_id"],

                "voter_name":
                voter["name"],

                "candidate_id":
                latest_vote["candidate_id"],

                "reference_id":
                latest_vote["reference_id"],

                "candidate_name":
                latest_vote["candidate_name"],

                "party_name":
                latest_vote["party_name"],

                "symbol":
                latest_vote["symbol"]

            }
        )

    return latest_votes


# ============================================================
# CREATE SHARES FOR A SINGLE ACTUAL VOTE
# ============================================================

def ensure_vote_shares(
    connection,
    vote
):

    vote_id = int(
        vote["vote_id"]
    )

    existing = connection.execute(
        """
        SELECT *
        FROM vote_shares
        WHERE vote_id = ?
        """,
        (
            vote_id,
        )
    ).fetchone()

    if existing is not None:

        share1_file = (
            BASE_DIR /
            existing["share1_path"]
        )

        share2_file = (
            BASE_DIR /
            existing["share2_path"]
        )

        if (
            share1_file.exists()
            and
            share2_file.exists()
        ):

            return existing

    share1_image, share2_image = (
        generate_visual_cryptography_shares(
            vote["candidate_id"]
        )
    )

    vote_folder = (
        SHARES_DIR /
        f"vote_{vote_id}"
    )

    vote_folder.mkdir(
        parents=True,
        exist_ok=True
    )

    share1_file = (
        vote_folder /
        "share_1.png"
    )

    share2_file = (
        vote_folder /
        "share_2.png"
    )

    save_share_image(
        share1_image,
        share1_file
    )

    save_share_image(
        share2_image,
        share2_file
    )

    share1_relative = (
        relative_share_path(
            share1_file
        )
    )

    share2_relative = (
        relative_share_path(
            share2_file
        )
    )

    if existing is None:

        connection.execute(
            """
            INSERT INTO vote_shares
            (
                vote_id,
                voter_id,
                reference_id,
                candidate_id,
                share1_path,
                share2_path
            )
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                vote_id,
                vote["voter_id"],
                vote["reference_id"],
                vote["candidate_id"],
                share1_relative,
                share2_relative
            )
        )

    else:

        connection.execute(
            """
            UPDATE vote_shares
            SET
                voter_id = ?,
                reference_id = ?,
                candidate_id = ?,
                share1_path = ?,
                share2_path = ?
            WHERE vote_id = ?
            """,
            (
                vote["voter_id"],
                vote["reference_id"],
                vote["candidate_id"],
                share1_relative,
                share2_relative,
                vote_id
            )
        )

    connection.commit()

    print()
    print(
        "Visual Cryptography shares created."
    )

    print(
        "Vote ID      :",
        vote_id
    )

    print(
        "Voter ID     :",
        vote["voter_id"]
    )

    print(
        "Candidate ID :",
        vote["candidate_id"]
    )

    print(
        "Share 1      :",
        share1_file
    )

    print(
        "Share 2      :",
        share2_file
    )

    return connection.execute(
        """
        SELECT *
        FROM vote_shares
        WHERE vote_id = ?
        """,
        (
            vote_id,
        )
    ).fetchone()


# ============================================================
# CREATE MISSING SHARES FOR EXISTING ACTUAL VOTES
# ============================================================

def initialize_existing_vote_shares():

    connection = get_connection()

    try:

        latest_votes = (
            get_latest_votes_for_registered_voters(
                connection
            )
        )

        print()
        print(
            "Checking existing votes for "
            "Visual Cryptography shares..."
        )

        for vote in latest_votes:

            ensure_vote_shares(
                connection,
                vote
            )

        print(
            "Existing vote share check completed."
        )

    except Exception as error:

        connection.rollback()

        print(
            "Existing vote share initialization error:",
            error
        )

    finally:

        connection.close()


initialize_existing_vote_shares()


# ============================================================
# FACE EMBEDDING FUNCTIONS
# ============================================================

def cosine_similarity(
    embedding1,
    embedding2
):

    embedding1 = np.asarray(
        embedding1,
        dtype=np.float32
    )

    embedding2 = np.asarray(
        embedding2,
        dtype=np.float32
    )

    norm1 = np.linalg.norm(
        embedding1
    )

    norm2 = np.linalg.norm(
        embedding2
    )

    if norm1 == 0 or norm2 == 0:

        return 0.0

    return float(
        np.dot(
            embedding1,
            embedding2
        )
        /
        (
            norm1 *
            norm2
        )
    )


# ============================================================
# LIVE FACE EMBEDDING
# ============================================================

def get_live_embedding(
    image_bytes
):

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_COLOR
    )

    if image is None:

        raise HTTPException(
            status_code=400,
            detail="Invalid image."
        )

    faces = face_app.get(image)

    if not faces:

        raise HTTPException(
            status_code=400,
            detail="No face detected."
        )

    largest_face = max(
        faces,
        key=lambda face:
        (
            face.bbox[2] -
            face.bbox[0]
        )
        *
        (
            face.bbox[3] -
            face.bbox[1]
        )
    )

    embedding = largest_face.embedding

    return np.asarray(
        embedding,
        dtype=np.float32
    )


# ============================================================
# EMBEDDING EXTRACTION HELPER
# ============================================================

def _extract_embedding_arrays(
    data
):

    extracted = []

    if isinstance(
        data,
        np.ndarray
    ):

        try:

            array = np.asarray(
                data,
                dtype=np.float32
            )

            if (
                array.ndim == 1
                and array.size >= 128
            ):

                extracted.append(
                    array
                )

                return extracted

            if (
                array.ndim == 2
                and array.shape[1] >= 128
            ):

                for row in array:

                    extracted.append(
                        np.asarray(
                            row,
                            dtype=np.float32
                        )
                    )

                return extracted

        except Exception:

            return extracted

    if isinstance(
        data,
        dict
    ):

        preferred_keys = [
            "embedding",
            "embeddings",
            "face_embedding",
            "face_embeddings",
            "vector",
            "vectors",
            "feature",
            "features"
        ]

        for key in preferred_keys:

            if key in data:

                value = data[key]

                nested_embeddings = (
                    _extract_embedding_arrays(
                        value
                    )
                )

                if nested_embeddings:

                    extracted.extend(
                        nested_embeddings
                    )

        if not extracted:

            for value in data.values():

                nested_embeddings = (
                    _extract_embedding_arrays(
                        value
                    )
                )

                if nested_embeddings:

                    extracted.extend(
                        nested_embeddings
                    )

        return extracted

    if isinstance(
        data,
        (list, tuple)
    ):

        try:

            array = np.asarray(
                data,
                dtype=np.float32
            )

            if (
                array.ndim == 1
                and array.size >= 128
            ):

                extracted.append(
                    array
                )

                return extracted

        except Exception:

            pass

        for item in data:

            nested_embeddings = (
                _extract_embedding_arrays(
                    item
                )
            )

            if nested_embeddings:

                extracted.extend(
                    nested_embeddings
                )

        return extracted

    return extracted


# ============================================================
# LOAD STORED EMBEDDINGS
# ============================================================

def load_embeddings(
    voter_id
):

    voter_folder = (
        DATASET_DIR /
        voter_id
    )

    embedding_file = (
        voter_folder /
        "embeddings.pkl"
    )

    if not embedding_file.exists():

        print()
        print(
            "Embedding file not found:"
        )

        print(
            embedding_file
        )

        return []

    try:

        with open(
            embedding_file,
            "rb"
        ) as file:

            data = pickle.load(
                file
            )

        embeddings = (
            _extract_embedding_arrays(
                data
            )
        )

        valid_embeddings = []

        for embedding in embeddings:

            try:

                embedding = np.asarray(
                    embedding,
                    dtype=np.float32
                )

                if (
                    embedding.ndim == 1
                    and embedding.size >= 128
                ):

                    valid_embeddings.append(
                        embedding
                    )

            except Exception:

                continue

        unique_embeddings = []

        seen_shapes = set()

        for embedding in valid_embeddings:

            shape_key = (
                embedding.shape,
                embedding.tobytes()
            )

            if shape_key not in seen_shapes:

                seen_shapes.add(
                    shape_key
                )

                unique_embeddings.append(
                    embedding
                )

        print()
        print(
            "Embedding file loaded:"
        )

        print(
            "Voter/Admin ID :",
            voter_id
        )

        print(
            "Embedding count:",
            len(unique_embeddings)
        )

        if unique_embeddings:

            print(
                "Embedding size :",
                unique_embeddings[0].shape
            )

        return unique_embeddings

    except Exception as error:

        print()
        print(
            "Embedding load error:",
            error
        )

        return []


# ============================================================
# SAVE NEW VOTER FACE EMBEDDING
# ============================================================

def save_voter_embedding(
    voter_id,
    embedding
):

    voter_folder = (
        DATASET_DIR /
        voter_id
    )

    voter_folder.mkdir(
        parents=True,
        exist_ok=True
    )

    embedding_file = (
        voter_folder /
        "embeddings.pkl"
    )

    embedding_array = np.asarray(
        embedding,
        dtype=np.float32
    )

    with open(
        embedding_file,
        "wb"
    ) as file:

        pickle.dump(
            [embedding_array],
            file
        )

    print()
    print(
        "New voter face embedding saved:"
    )

    print(
        "Voter ID :",
        voter_id
    )

    print(
        "File     :",
        embedding_file
    )


# ============================================================
# BEST FACE SIMILARITY
# ============================================================

def calculate_best_similarity(
    live_embedding,
    stored_embeddings
):

    if not stored_embeddings:

        return 0.0

    similarities = []

    for stored in stored_embeddings:

        try:

            similarity = cosine_similarity(
                live_embedding,
                stored
            )

            similarities.append(
                similarity
            )

        except Exception as error:

            print(
                "Similarity calculation error:",
                error
            )

    if not similarities:

        return 0.0

    return max(
        similarities
    )


# ============================================================
# LOGIN MODELS
# ============================================================

class LoginRequest(BaseModel):

    username: str
    password: str

class SendEmailOTPRequest(BaseModel):
    voter_id: str
    email: str


class VerifyEmailOTPRequest(BaseModel):
    voter_id: str
    email: str
    otp: str


class VoteRequest(BaseModel):

    voter_id: str
    candidate_id: int


class UpdateVoterEmailRequest(BaseModel):

    email: str
    class SendEmailOTPRequest(BaseModel):

        voter_id: str
        email: str


    class VerifyEmailOTPRequest(BaseModel):

        voter_id: str
        email: str
        otp: str
# ============================================================
# EMAIL OTP HELPERS
# ============================================================

def generate_email_otp():
    return f"{random.randint(100000, 999999)}"


def send_email_otp_message(
    recipient_email,
    otp
):

    message = MIMEMultipart()

    message["From"] = SMTP_FROM_EMAIL
    message["To"] = recipient_email
    message["Subject"] = "SmartPoll Email Verification OTP"

    body = f"""
Hello,

Your SmartPoll verification OTP is:

{otp}

This OTP is valid for {OTP_EXPIRY_MINUTES} minutes.

Maximum verification attempts: {OTP_MAX_ATTEMPTS}

Please do not share this OTP with anyone.

Regards,
SmartPoll
"""

    message.attach(
        MIMEText(
            body,
            "plain"
        )
    )

    with smtplib.SMTP(
        SMTP_HOST,
        SMTP_PORT
    ) as server:

        server.starttls()

        server.login(
            SMTP_USERNAME,
            SMTP_PASSWORD
        )

        server.sendmail(
            SMTP_FROM_EMAIL,
            recipient_email,
            message.as_string()
        )


# ============================================================
# SEND EMAIL OTP
# ============================================================

@app.post("/auth/send-email-otp")
def send_email_otp(request: SendEmailOTPRequest):
    voter_id = request.voter_id.strip().upper()
    email = request.email.strip().lower()

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    email = (
        email
        .strip()
        .lower()
    )

    if not voter_id:

        raise HTTPException(
            status_code=400,
            detail="Voter ID is required."
        )

    if (
        not email
        or "@" not in email
        or "." not in email.rsplit("@", 1)[-1]
    ):

        raise HTTPException(
            status_code=400,
            detail="Valid email is required."
        )

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT voter_id, name, email
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter ID not found."
            )

        registered_email = (
            str(
                voter["email"] or ""
            )
            .strip()
            .lower()
        )

        if not registered_email:

            raise HTTPException(
                status_code=400,
                detail=
                "No registered email found for this voter."
            )

        if email != registered_email:

            raise HTTPException(
                status_code=400,
                detail=
                "Entered email does not match the registered email."
            )

        # ----------------------------------------------------
        # INVALIDATE PREVIOUS UNUSED OTP
        # ----------------------------------------------------

        connection.execute(
            """
            UPDATE email_otps
            SET used = 1
            WHERE voter_id = ?
            AND used = 0
            """,
            (voter_id,)
        )

        # ----------------------------------------------------
        # GENERATE OTP
        # ----------------------------------------------------

        otp = generate_email_otp()

        otp_hash = str(
            __import__("hashlib")
            .sha256(
                otp.encode("utf-8")
            )
            .hexdigest()
        )

        connection.execute(
            """
            INSERT INTO email_otps
            (
                voter_id,
                email,
                otp_hash,
                expires_at,
                attempts,
                used
            )
            VALUES
            (
                ?,
                ?,
                ?,
                datetime(
                    'now',
                    ?
                ),
                0,
                0
            )
            """,
            (
                voter_id,
                email,
                otp_hash,
                f"+{OTP_EXPIRY_MINUTES} minutes"
            )
        )

        connection.commit()

        # ----------------------------------------------------
        # SEND EMAIL
        # ----------------------------------------------------

        try:

            send_email_otp_message(
                email,
                otp
            )

        except Exception as email_error:

            connection.execute(
                """
                UPDATE email_otps
                SET used = 1
                WHERE voter_id = ?
                AND used = 0
                """,
                (voter_id,)
            )

            connection.commit()

            print(
                "Email OTP sending error:",
                email_error
            )

            raise HTTPException(
                status_code=500,
                detail=
                "Unable to send OTP email."
            )

        print()
        print(
            "Email OTP sent successfully."
        )

        print(
            "Voter ID:",
            voter_id
        )

        print(
            "Email:",
            email
        )

        return {

            "success": True,

            "message":
            "OTP sent successfully to the registered email.",

            "voter_id":
            voter_id,

            "email":
            email,

            "expires_in_minutes":
            OTP_EXPIRY_MINUTES

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Send email OTP error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to send email OTP."
        )

    finally:

        connection.close()


# ============================================================
# VERIFY EMAIL OTP
# ============================================================

@app.post("/auth/verify-email-otp")
def verify_email_otp(request: VerifyEmailOTPRequest):
    voter_id = request.voter_id.strip().upper()
    email = request.email.strip().lower()
    otp = request.otp.strip()

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    email = (
        email
        .strip()
        .lower()
    )

    otp = otp.strip()

    if not voter_id:

        raise HTTPException(
            status_code=400,
            detail="Voter ID is required."
        )

    if not email:

        raise HTTPException(
            status_code=400,
            detail="Email is required."
        )

    if (
        len(otp) != 6
        or not otp.isdigit()
    ):

        raise HTTPException(
            status_code=400,
            detail="Enter a valid 6-digit OTP."
        )

    connection = get_connection()

    try:

        otp_record = connection.execute(
            """
            SELECT *
            FROM email_otps
            WHERE voter_id = ?
            AND email = ?
            AND used = 0
            ORDER BY id DESC
            LIMIT 1
            """,
            (
                voter_id,
                email
            )
        ).fetchone()

        if otp_record is None:

            raise HTTPException(
                status_code=400,
                detail=
                "OTP not found or already used."
            )

        # ----------------------------------------------------
        # CHECK EXPIRY
        # ----------------------------------------------------

        expired = connection.execute(
            """
            SELECT
                datetime('now') >
                datetime(?) AS expired
            """,
            (
                otp_record["expires_at"],
            )
        ).fetchone()["expired"]

        if int(expired) == 1:

            connection.execute(
                """
                UPDATE email_otps
                SET used = 1
                WHERE id = ?
                """,
                (
                    otp_record["id"],
                )
            )

            connection.commit()

            raise HTTPException(
                status_code=400,
                detail=
                "OTP has expired. Please request a new OTP."
            )

        # ----------------------------------------------------
        # CHECK MAXIMUM ATTEMPTS
        # ----------------------------------------------------

        attempts = int(
            otp_record["attempts"] or 0
        )

        if attempts >= OTP_MAX_ATTEMPTS:

            connection.execute(
                """
                UPDATE email_otps
                SET used = 1
                WHERE id = ?
                """,
                (
                    otp_record["id"],
                )
            )

            connection.commit()

            raise HTTPException(
                status_code=400,
                detail=
                "Maximum OTP attempts exceeded. Please request a new OTP."
            )

        # ----------------------------------------------------
        # HASH ENTERED OTP
        # ----------------------------------------------------

        entered_hash = str(
            __import__("hashlib")
            .sha256(
                otp.encode("utf-8")
            )
            .hexdigest()
        )

        # ----------------------------------------------------
        # CHECK OTP
        # ----------------------------------------------------

        if entered_hash != otp_record["otp_hash"]:

            new_attempts = attempts + 1

            connection.execute(
                """
                UPDATE email_otps
                SET attempts = ?
                WHERE id = ?
                """,
                (
                    new_attempts,
                    otp_record["id"]
                )
            )

            connection.commit()

            remaining_attempts = max(
                0,
                OTP_MAX_ATTEMPTS -
                new_attempts
            )

            raise HTTPException(
                status_code=400,
                detail=(
                    "Invalid OTP. "
                    f"{remaining_attempts} attempts remaining."
                )
            )

        # ----------------------------------------------------
        # OTP VERIFIED
        # ----------------------------------------------------

        connection.execute(
            """
            UPDATE email_otps
            SET used = 1
            WHERE id = ?
            """,
            (
                otp_record["id"],
            )
        )

        connection.commit()

        print()
        print(
            "Email OTP verified successfully."
        )

        print(
            "Voter ID:",
            voter_id
        )

        return {

            "success": True,

            "verified":
            True,

            "message":
            "Email OTP verified successfully.",

            "voter_id":
            voter_id

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Verify email OTP error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to verify email OTP."
        )

    finally:

        connection.close()

# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():

    return {

        "success": True,

        "project": "SmartPoll",

        "message":
        "SmartPoll backend is running.",

        "face_model":
        "InsightFace buffalo_l",

        "face_threshold":
        FACE_THRESHOLD

    }


# ============================================================
# HEALTH
# ============================================================

@app.get("/health")
def health():

    return {

        "success": True,

        "status": "connected",

        "database":
        str(DB_PATH),

        "face_model":
        "InsightFace buffalo_l",

        "threshold":
        FACE_THRESHOLD

    }


# ============================================================
# VOTER DETAILS
# ============================================================

@app.get("/voter/{voter_id}")
def get_voter(
    voter_id: str
):

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT *
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter ID not found."
            )

        return {

            "success": True,

            "voter":
            dict(voter)

        }

    finally:

        connection.close()


# ============================================================
# CANDIDATES FOR VOTER
# ============================================================

@app.get("/candidates/{voter_id}")
def get_candidates(
    voter_id: str
):

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT
                district,
                taluk,
                block,
                panchayat,
                ward,
                booth
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter not found."
            )

        candidates = connection.execute(
            """
            SELECT *
            FROM candidates
            WHERE district = ?
            AND taluk = ?
            AND block = ?
            AND panchayat = ?
            AND ward = ?
            AND booth = ?
            ORDER BY id ASC
            """,
            (
                voter["district"],
                voter["taluk"],
                voter["block"],
                voter["panchayat"],
                voter["ward"],
                voter["booth"]
            )
        ).fetchall()

        return {

            "success": True,

            "candidates": [
                dict(candidate)
                for candidate in candidates
            ]

        }

    finally:

        connection.close()


# ============================================================
# ALL CANDIDATES FOR ADMIN
# ============================================================

@app.get("/admin/candidates")
def get_all_candidates():

    connection = get_connection()

    try:

        candidates = connection.execute(
            """
            SELECT *
            FROM candidates
            ORDER BY id ASC
            """
        ).fetchall()

        return {

            "success": True,

            "count":
            len(candidates),

            "candidates": [
                dict(candidate)
                for candidate
                in candidates
            ]

        }

    finally:

        connection.close()


# ============================================================
# ADMIN - GET ALL ENROLLED MEMBERS
# ============================================================

@app.get("/admin/voters")
def get_all_voters():

    connection = get_connection()

    try:

        voters = connection.execute(
            """
            SELECT *
            FROM voters
            ORDER BY id ASC
            """
        ).fetchall()

        return {

            "success": True,

            "count":
            len(voters),

            "voters": [
                dict(voter)
                for voter in voters
            ]

        }

    finally:

        connection.close()


# ============================================================
# ADMIN - UPDATE REGISTERED VOTER EMAIL
# ============================================================

@app.put("/admin/voters/{voter_id}/email")
def update_voter_email(
    voter_id: str,
    request: UpdateVoterEmailRequest
):

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    email = (
        request.email
        .strip()
        .lower()
    )

    if not voter_id:

        raise HTTPException(
            status_code=400,
            detail="Voter ID is required."
        )

    if (
        not email
        or "@" not in email
        or "." not in email.rsplit("@", 1)[-1]
    ):

        raise HTTPException(
            status_code=400,
            detail="Valid email is required."
        )

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT voter_id, email
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter ID not found."
            )

        connection.execute(
            """
            UPDATE voters
            SET email = ?
            WHERE voter_id = ?
            """,
            (
                email,
                voter_id
            )
        )

        # Invalidate any unused OTP issued for the old email.
        connection.execute(
            """
            UPDATE email_otps
            SET used = 1
            WHERE voter_id = ?
              AND used = 0
            """,
            (voter_id,)
        )

        connection.commit()

        return {

            "success": True,

            "message":
            "Registered email updated successfully.",

            "voter_id":
            voter_id,

            "email":
            email

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Update voter email error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail="Unable to update voter email."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN - ADD NEW MEMBER
# ============================================================

@app.post("/admin/voters/add")
async def add_voter(
    voter_id: str = Form(...),
    name: str = Form(...),
    phone: str = Form(""),
    email: str = Form(""),
    district: str = Form(""),
    taluk: str = Form(""),
    block: str = Form(""),
    panchayat: str = Form(""),
    ward: str = Form(""),
    booth: str = Form(""),
    image: UploadFile = File(...)
):

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    name = name.strip()
    phone = phone.strip()
    email = email.strip().lower()
    district = district.strip()
    taluk = taluk.strip()
    block = block.strip()
    panchayat = panchayat.strip()
    ward = ward.strip()
    booth = booth.strip()

    if not voter_id:

        raise HTTPException(
            status_code=400,
            detail="Voter ID is required."
        )

    if not name:

        raise HTTPException(
            status_code=400,
            detail="Name is required."
        )

    if not email or "@" not in email or "." not in email.rsplit("@", 1)[-1]:

        raise HTTPException(
            status_code=400,
            detail="Valid email is required."
        )

    connection = get_connection()

    try:

        # ----------------------------------------------------
        # CHECK DUPLICATE VOTER ID
        # ----------------------------------------------------

        existing_voter = connection.execute(
            """
            SELECT *
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if existing_voter is not None:

            raise HTTPException(
                status_code=409,
                detail="Voter ID already exists."
            )

        # ----------------------------------------------------
        # READ FACE IMAGE
        # ----------------------------------------------------

        image_bytes = await image.read()

        if not image_bytes:

            raise HTTPException(
                status_code=400,
                detail="Face image is required."
            )

        # ----------------------------------------------------
        # CREATE FACE EMBEDDING
        # ----------------------------------------------------

        live_embedding = get_live_embedding(
            image_bytes
        )

        # ----------------------------------------------------
        # INSERT NEW VOTER
        # ----------------------------------------------------

        connection.execute(
            """
            INSERT INTO voters
            (
                voter_id,
                name,
                phone,
                email,
                district,
                taluk,
                block,
                panchayat,
                ward,
                booth,
                face_status,
                voted
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                voter_id,
                name,
                phone,
                email,
                district,
                taluk,
                block,
                panchayat,
                ward,
                booth,
                "Registered",
                0
            )
        )

        # ----------------------------------------------------
        # SAVE FACE EMBEDDING
        # ----------------------------------------------------

        try:

            save_voter_embedding(
                voter_id,
                live_embedding
            )

        except Exception as embedding_error:

            # If embedding saving fails,
            # remove the newly inserted voter.
            connection.execute(
                """
                DELETE FROM voters
                WHERE voter_id = ?
                """,
                (voter_id,)
            )

            connection.commit()

            print(
                "Face embedding save error:",
                embedding_error
            )

            raise HTTPException(
                status_code=500,
                detail=
                "Unable to save voter face data."
            )

        connection.commit()

        print()
        print(
            "New SmartPoll voter added."
        )

        print(
            "Voter ID :",
            voter_id
        )

        print(
            "Name     :",
            name
        )

        return {

            "success": True,

            "message":
            "New voter registered successfully.",

            "voter": {

                "voter_id":
                voter_id,

                "name":
                name,

                "phone":
                phone,

                "email":
                email,

                "district":
                district,

                "taluk":
                taluk,

                "block":
                block,

                "panchayat":
                panchayat,

                "ward":
                ward,

                "booth":
                booth,

                "face_status":
                "Registered",

                "voted":
                0

            }

        }

    except HTTPException:

        raise

    except sqlite3.IntegrityError as error:

        connection.rollback()

        print(
            "Add voter database error:",
            error
        )

        raise HTTPException(
            status_code=400,
            detail=
            "Unable to add voter. Voter ID may already exist."
        )

    except Exception as error:

        connection.rollback()

        print(
            "Add voter error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to add new voter."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN - REMOVE MEMBER
# ============================================================

@app.delete("/admin/voters/{voter_id}")
def remove_voter(
    voter_id: str
):

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT *
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter not found."
            )

        # ----------------------------------------------------
        # REMOVE VISUAL CRYPTOGRAPHY SHARE FILES
        # ----------------------------------------------------

        vote_share_rows = connection.execute(
            """
            SELECT
                vote_id,
                share1_path,
                share2_path
            FROM vote_shares
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchall()

        for share in vote_share_rows:

            vote_id = share["vote_id"]

            vote_folder = (
                SHARES_DIR /
                f"vote_{vote_id}"
            )

            if vote_folder.exists():

                try:

                    shutil.rmtree(
                        vote_folder
                    )

                except Exception as error:

                    print(
                        "Share folder remove error:",
                        error
                    )

        # ----------------------------------------------------
        # REMOVE SHARE RECORDS
        # ----------------------------------------------------

        connection.execute(
            """
            DELETE FROM vote_shares
            WHERE voter_id = ?
            """,
            (voter_id,)
        )

        # ----------------------------------------------------
        # REMOVE VERIFICATION LOGS
        # ----------------------------------------------------

        connection.execute(
            """
            DELETE FROM verification_logs
            WHERE voter_id = ?
            """,
            (voter_id,)
        )

        # ----------------------------------------------------
        # REMOVE VOTES
        #
        # This keeps the database consistent because the
        # voter is completely removed from the registered
        # voter list.
        # ----------------------------------------------------

        connection.execute(
            """
            DELETE FROM votes
            WHERE voter_id = ?
            """,
            (voter_id,)
        )

        # ----------------------------------------------------
        # REMOVE VOTER
        # ----------------------------------------------------

        connection.execute(
            """
            DELETE FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        )

        connection.commit()

        # ----------------------------------------------------
        # REMOVE FACE DATASET
        # ----------------------------------------------------

        voter_folder = (
            DATASET_DIR /
            voter_id
        )

        if voter_folder.exists():

            try:

                shutil.rmtree(
                    voter_folder
                )

            except Exception as error:

                print(
                    "Face dataset remove error:",
                    error
                )

        print()
        print(
            "SmartPoll voter removed."
        )

        print(
            "Voter ID :",
            voter_id
        )

        return {

            "success": True,

            "message":
            "Voter removed successfully.",

            "voter_id":
            voter_id

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Remove voter error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to remove voter."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN - ADD CANDIDATE
# ============================================================

@app.post("/admin/candidates/add")
def add_candidate(
    candidate_name: str = Form(...),
    party_name: str = Form(...),
    district: str = Form(""),
    taluk: str = Form(""),
    block: str = Form(""),
    panchayat: str = Form(""),
    ward: str = Form(""),
    booth: str = Form(""),
    symbol: str = Form("")
):

    candidate_name = candidate_name.strip()
    party_name = party_name.strip()
    district = district.strip()
    taluk = taluk.strip()
    block = block.strip()
    panchayat = panchayat.strip()
    ward = ward.strip()
    booth = booth.strip()
    symbol = symbol.strip()

    if not candidate_name:

        raise HTTPException(
            status_code=400,
            detail="Candidate name is required."
        )

    if not party_name:

        raise HTTPException(
            status_code=400,
            detail="Party name is required."
        )

    connection = get_connection()

    try:

        # ----------------------------------------------------
        # CHECK DUPLICATE CANDIDATE
        # ----------------------------------------------------

        existing_candidate = connection.execute(
            """
            SELECT *
            FROM candidates
            WHERE candidate_name = ?
            AND party_name = ?
            AND district = ?
            AND taluk = ?
            AND block = ?
            AND panchayat = ?
            AND ward = ?
            AND booth = ?
            """,
            (
                candidate_name,
                party_name,
                district,
                taluk,
                block,
                panchayat,
                ward,
                booth
            )
        ).fetchone()

        if existing_candidate is not None:

            raise HTTPException(
                status_code=409,
                detail="Candidate already exists."
            )

        # ----------------------------------------------------
        # INSERT CANDIDATE
        # ----------------------------------------------------

        cursor = connection.execute(
            """
            INSERT INTO candidates
            (
                candidate_name,
                party_name,
                district,
                taluk,
                block,
                panchayat,
                ward,
                booth,
                symbol
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                candidate_name,
                party_name,
                district,
                taluk,
                block,
                panchayat,
                ward,
                booth,
                symbol
            )
        )

        candidate_id = cursor.lastrowid

        connection.commit()

        print()
        print(
            "New SmartPoll candidate added."
        )

        print(
            "Candidate ID :",
            candidate_id
        )

        print(
            "Candidate    :",
            candidate_name
        )

        print(
            "Party        :",
            party_name
        )

        return {

            "success": True,

            "message":
            "Candidate added successfully.",

            "candidate": {

                "id":
                candidate_id,

                "candidate_name":
                candidate_name,

                "party_name":
                party_name,

                "district":
                district,

                "taluk":
                taluk,

                "block":
                block,

                "panchayat":
                panchayat,

                "ward":
                ward,

                "booth":
                booth,

                "symbol":
                symbol

            }

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Add candidate error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to add candidate."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN - REMOVE CANDIDATE
# ============================================================

@app.delete("/admin/candidates/{candidate_id}")
def remove_candidate(
    candidate_id: int
):

    connection = get_connection()

    try:

        candidate = connection.execute(
            """
            SELECT *
            FROM candidates
            WHERE id = ?
            """,
            (candidate_id,)
        ).fetchone()

        if candidate is None:

            raise HTTPException(
                status_code=404,
                detail="Candidate not found."
            )

        # ----------------------------------------------------
        # DO NOT DELETE A CANDIDATE THAT ALREADY HAS VOTES.
        #
        # This prevents existing vote / result /
        # visual-cryptography data from becoming invalid.
        # ----------------------------------------------------

        vote_count = connection.execute(
            """
            SELECT COUNT(*) AS count
            FROM votes
            WHERE candidate_id = ?
            """,
            (candidate_id,)
        ).fetchone()["count"]

        if int(vote_count) > 0:

            raise HTTPException(
                status_code=400,
                detail=(
                    "This candidate already has votes "
                    "and cannot be removed."
                )
            )

        connection.execute(
            """
            DELETE FROM candidates
            WHERE id = ?
            """,
            (candidate_id,)
        )

        connection.commit()

        print()
        print(
            "SmartPoll candidate removed."
        )

        print(
            "Candidate ID :",
            candidate_id
        )

        print(
            "Candidate    :",
            candidate["candidate_name"]
        )

        return {

            "success": True,

            "message":
            "Candidate removed successfully.",

            "candidate_id":
            candidate_id

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Remove candidate error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to remove candidate."
        )

    finally:

        connection.close()


# ============================================================
# VOTER FACE VERIFICATION
# ============================================================

@app.post("/verify-face")
async def verify_face(
    voter_id: str = Form(...),
    image: UploadFile = File(...)
):

    voter_id = (
        voter_id
        .strip()
        .upper()
    )

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT *
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter not found."
            )

        image_bytes = await image.read()

        live_embedding = (
            get_live_embedding(
                image_bytes
            )
        )

        stored_embeddings = (
            load_embeddings(
                voter_id
            )
        )

        if not stored_embeddings:

            raise HTTPException(
                status_code=404,
                detail=
                "Stored face embeddings not found."
            )

        similarity = (
            calculate_best_similarity(
                live_embedding,
                stored_embeddings
            )
        )

        is_match = (
            similarity >=
            FACE_THRESHOLD
        )

        result = (
            "MATCH"
            if is_match
            else
            "NO MATCH"
        )

        connection.execute(
            """
            INSERT INTO verification_logs
            (
                voter_id,
                verification_type,
                similarity,
                threshold,
                result
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                voter_id,
                "Voter Face",
                similarity,
                FACE_THRESHOLD,
                result
            )
        )

        connection.commit()

        print()
        print(
            "--------------------------------------------"
        )

        print(
            "Voter ID       :",
            voter_id
        )

        print(
            "Voter Name     :",
            voter["name"]
        )

        print(
            "Face Similarity:",
            round(
                similarity,
                4
            )
        )

        print(
            "Face Threshold :",
            FACE_THRESHOLD
        )

        print(
            "Face Result    :",
            result
        )

        print(
            "--------------------------------------------"
        )

        print()

        return {

            "success": True,

            "verified":
            is_match,

            "match":
            is_match,

            "voter_id":
            voter_id,

            "name":
            voter["name"],

            "similarity":
            round(
                similarity,
                4
            ),

            "threshold":
            FACE_THRESHOLD,

            "result":
            result,

            "message":
            (
                "Face MATCH."
                if is_match
                else
                "Face NO MATCH."
            )

        }

    finally:

        connection.close()


# ============================================================
# ADMIN LOGIN
# ============================================================

@app.post("/admin/login")
def admin_login(
    request: LoginRequest
):

    connection = get_connection()

    try:

        admin = connection.execute(
            """
            SELECT *
            FROM admins
            WHERE username = ?
            AND password = ?
            """,
            (
                request.username.strip(),
                request.password
            )
        ).fetchone()

        if admin is None:

            raise HTTPException(
                status_code=401,
                detail=
                "Invalid username or password."
            )

        return {

            "success": True,

            "admin_id":
            admin["admin_id"],

            "username":
            admin["username"],

            "name":
            admin["name"],

            "face_status":
            admin["face_status"],

            "message":
            "Admin login successful."

        }

    finally:

        connection.close()

# ============================================================
# GET ADMIN PROFILE
# ============================================================

@app.get("/admin/profile")
def get_admin_profile():

    connection = get_connection()

    try:

        admin = connection.execute(
            """
            SELECT
                admin_id,
                username,
                name,
                email,
                phone,
                face_status
            FROM admins
            WHERE admin_id = ?
            """,
            ("ADMIN001",)
        ).fetchone()

        if admin is None:

            raise HTTPException(
                status_code=404,
                detail="Admin account not found."
            )

        return {
            "success": True,
            "admin_id": admin["admin_id"],
            "username": admin["username"],
            "name": admin["name"],
            "email": admin["email"] or "",
            "phone": admin["phone"] or "",
            "face_status": admin["face_status"] or "Not Registered"
        }

    finally:

        connection.close()
# ============================================================
# GET ADMIN PROFILE
# ============================================================

@app.get("/admin/profile")
def get_admin_profile():

    connection = get_connection()

    try:

        admin = connection.execute(
            """
            SELECT
                admin_id,
                username,
                name,
                email,
                phone,
                face_status
            FROM admins
            WHERE admin_id = ?
            """,
            ("ADMIN001",)
        ).fetchone()

        if admin is None:

            raise HTTPException(
                status_code=404,
                detail="Admin account not found."
            )

        return {
            "success": True,
            "admin_id": admin["admin_id"],
            "username": admin["username"],
            "name": admin["name"],
            "email": admin["email"] or "",
            "phone": admin["phone"] or "",
            "face_status": admin["face_status"] or "Not Registered"
        }

    finally:

        connection.close()
# ============================================================
# UPDATE ADMIN PROFILE
# ============================================================

@app.put("/admin/profile")
def update_admin_profile(
    name: str = Form(...),
    email: str = Form(""),
    phone: str = Form("")
):

    connection = get_connection()

    try:

        admin = connection.execute(
            """
            SELECT *
            FROM admins
            WHERE admin_id = ?
            """,
            ("ADMIN001",)
        ).fetchone()

        if admin is None:

            raise HTTPException(
                status_code=404,
                detail="Admin account not found."
            )

        name = name.strip()
        email = email.strip()
        phone = phone.strip()

        if not name:

            raise HTTPException(
                status_code=400,
                detail="Admin name is required."
            )

        connection.execute(
            """
            UPDATE admins
            SET
                name = ?,
                email = ?,
                phone = ?
            WHERE admin_id = ?
            """,
            (
                name,
                email,
                phone,
                "ADMIN001"
            )
        )

        connection.commit()

        updated_admin = connection.execute(
            """
            SELECT
                admin_id,
                username,
                name,
                email,
                phone,
                face_status
            FROM admins
            WHERE admin_id = ?
            """,
            ("ADMIN001",)
        ).fetchone()

        return {
            "success": True,
            "admin_id": updated_admin["admin_id"],
            "username": updated_admin["username"],
            "name": updated_admin["name"],
            "email": updated_admin["email"] or "",
            "phone": updated_admin["phone"] or "",
            "face_status": updated_admin["face_status"] or "Not Registered",
            "message": "Admin profile updated successfully."
        }

    except HTTPException:
        raise

    except Exception as error:

        connection.rollback()

        print(
            "Update admin profile error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail="Unable to update admin profile."
        )

    finally:
        connection.close()


# ============================================================
# ADMIN FACE VERIFICATION
# ============================================================

@app.post("/verify-admin-face")
async def verify_admin_face(
    image: UploadFile = File(...)
):

    admin_id = "ADMIN001"

    connection = get_connection()

    try:

        admin = connection.execute(
            """
            SELECT *
            FROM admins
            WHERE admin_id = ?
            """,
            (admin_id,)
        ).fetchone()

        if admin is None:

            raise HTTPException(
                status_code=404,
                detail=
                "Admin account not found."
            )

        image_bytes = await image.read()

        live_embedding = (
            get_live_embedding(
                image_bytes
            )
        )

        stored_embeddings = (
            load_embeddings(
                admin_id
            )
        )

        if not stored_embeddings:

            raise HTTPException(
                status_code=404,
                detail=
                "Admin face embeddings not found."
            )

        similarity = (
            calculate_best_similarity(
                live_embedding,
                stored_embeddings
            )
        )

        is_match = (
            similarity >=
            FACE_THRESHOLD
        )

        result = (
            "MATCH"
            if is_match
            else
            "NO MATCH"
        )

        connection.execute(
            """
            INSERT INTO verification_logs
            (
                voter_id,
                verification_type,
                similarity,
                threshold,
                result
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                admin_id,
                "Admin Face",
                similarity,
                FACE_THRESHOLD,
                result
            )
        )

        connection.commit()

        print()
        print(
            "--------------------------------------------"
        )

        print(
            "Admin ID       :",
            admin_id
        )

        print(
            "Admin Name     :",
            admin["name"]
        )

        print(
            "Face Similarity:",
            round(
                similarity,
                4
            )
        )

        print(
            "Face Threshold :",
            FACE_THRESHOLD
        )

        print(
            "Face Result    :",
            result
        )

        print(
            "--------------------------------------------"
        )

        print()

        return {

            "success": True,

            "verified":
            is_match,

            "match":
            is_match,

            "admin_id":
            admin_id,

            "name":
            admin["name"],

            "similarity":
            round(
                similarity,
                4
            ),

            "threshold":
            FACE_THRESHOLD,

            "result":
            result,

            "message":
            (
                "Face MATCH."
                if is_match
                else
                "Face NO MATCH."
            )

        }

    finally:

        connection.close()


# ============================================================
# VERIFICATION LOGS
# ============================================================

@app.get("/verification-logs")
def get_verification_logs():

    connection = get_connection()

    try:

        logs = connection.execute(
            """
            SELECT *
            FROM verification_logs
            ORDER BY id DESC
            """
        ).fetchall()

        formatted_logs = []

        for log in logs:

            log_data = dict(log)

            old_result = (
                str(
                    log_data.get(
                        "result",
                        ""
                    )
                )
                .strip()
                .upper()
            )

            if old_result in [
                "VERIFIED",
                "MATCH"
            ]:

                normalized_result = "MATCH"

            elif old_result in [
                "FAILED",
                "FAIL",
                "NO MATCH",
                "UNVERIFIED"
            ]:

                normalized_result = "NO MATCH"

            else:

                similarity = (
                    log_data.get(
                        "similarity"
                    )
                )

                threshold = (
                    log_data.get(
                        "threshold"
                    )
                )

                if (
                    similarity is not None
                    and
                    threshold is not None
                ):

                    try:

                        normalized_result = (
                            "MATCH"
                            if float(similarity)
                            >= float(threshold)
                            else
                            "NO MATCH"
                        )

                    except Exception:

                        normalized_result = "NO MATCH"

                else:

                    normalized_result = "NO MATCH"

            log_data["result"] = (
                normalized_result
            )

            log_data["match"] = (
                normalized_result == "MATCH"
            )

            formatted_logs.append(
                log_data
            )

        return {

            "success": True,

            "count":
            len(formatted_logs),

            "logs":
            formatted_logs

        }

    finally:

        connection.close()


# ============================================================
# SUBMIT VOTE
# ============================================================

@app.post("/submit-vote")
def submit_vote(
    request: VoteRequest
):

    voter_id = (
        request.voter_id
        .strip()
        .upper()
    )

    candidate_id = request.candidate_id

    connection = get_connection()

    try:

        voter = connection.execute(
            """
            SELECT *
            FROM voters
            WHERE voter_id = ?
            """,
            (voter_id,)
        ).fetchone()

        if voter is None:

            raise HTTPException(
                status_code=404,
                detail="Voter not found."
            )

        # ----------------------------------------------------
        # SPV001 CAN VOTE MULTIPLE TIMES FOR DEMO.
        # OTHER VOTERS CAN VOTE ONLY ONCE.
        # ----------------------------------------------------

        if (
            voter_id != "SPV001"
            and int(voter["voted"] or 0) == 1
        ):

            raise HTTPException(
                status_code=400,
                detail=
                "This voter has already voted."
            )

        candidate = connection.execute(
            """
            SELECT *
            FROM candidates
            WHERE id = ?
            """,
            (candidate_id,)
        ).fetchone()

        if candidate is None:

            raise HTTPException(
                status_code=404,
                detail="Candidate not found."
            )

        location_fields = [
            "district",
            "taluk",
            "block",
            "panchayat",
            "ward",
            "booth"
        ]

        for field in location_fields:

            if (
                voter[field]
                !=
                candidate[field]
            ):

                raise HTTPException(
                    status_code=400,
                    detail=
                    "Candidate is not available "
                    "for this voter."
                )

        reference_id = (
            "SP-"
            +
            uuid.uuid4()
            .hex[:12]
            .upper()
        )

        cursor = connection.execute(
            """
            INSERT INTO votes
            (
                voter_id,
                candidate_id,
                reference_id
            )
            VALUES (?, ?, ?)
            """,
            (
                voter_id,
                candidate_id,
                reference_id
            )
        )

        vote_id = cursor.lastrowid

        if voter_id != "SPV001":

            connection.execute(
                """
                UPDATE voters
                SET voted = 1
                WHERE voter_id = ?
                """,
                (voter_id,)
            )

        connection.commit()

        # ----------------------------------------------------
        # CREATE VISUAL CRYPTOGRAPHY SHARES
        # ----------------------------------------------------

        vote_data = {

            "vote_id":
            vote_id,

            "voter_id":
            voter_id,

            "reference_id":
            reference_id,

            "candidate_id":
            candidate["id"]

        }

        ensure_vote_shares(
            connection,
            vote_data
        )

        return {

            "success": True,

            "message":
            "Vote registered successfully.",

            "reference_id":
            reference_id,

            "voter_id":
            voter_id,

            "voter_name":
            voter["name"],

            "candidate_id":
            candidate["id"],

            "candidate_name":
            candidate["candidate_name"],

            "party_name":
            candidate["party_name"],

            "symbol":
            candidate["symbol"]

        }

    except HTTPException:

        raise

    except Exception as error:

        connection.rollback()

        print(
            "Vote submission error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to register vote."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN DASHBOARD
# ============================================================

@app.get("/admin/dashboard")
def get_admin_dashboard():

    connection = get_connection()

    try:

        total_voters = connection.execute(
            """
            SELECT COUNT(*) AS count
            FROM voters
            """
        ).fetchone()["count"]

        voted_voters = connection.execute(
            """
            SELECT COUNT(DISTINCT voter_id) AS count
            FROM votes
            WHERE voter_id IN (
                SELECT voter_id
                FROM voters
            )
            """
        ).fetchone()["count"]

        remaining_voters = max(
            0,
            total_voters - voted_voters
        )

        total_candidates = connection.execute(
            """
            SELECT COUNT(*) AS count
            FROM candidates
            """
        ).fetchone()["count"]

        database_status = "Connected"

        face_ml_status = "Active"

        return {

            "success": True,

            "total_voters":
            total_voters,

            "voted_voters":
            voted_voters,

            "remaining_voters":
            remaining_voters,

            "total_candidates":
            total_candidates,

            "face_ml":
            face_ml_status,

            "database":
            database_status

        }

    except Exception as error:

        print(
            "Admin dashboard error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to load dashboard data."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN RESULTS
# ============================================================

@app.get("/admin/results")
def get_admin_results():

    connection = get_connection()

    try:

        vote_columns = connection.execute(
            """
            PRAGMA table_info(votes)
            """
        ).fetchall()

        vote_column_names = {
            column["name"]
            for column in vote_columns
        }

        if "created_at" in vote_column_names:

            vote_time_column = "created_at"

        elif "timestamp" in vote_column_names:

            vote_time_column = "timestamp"

        else:

            vote_time_column = None

        voters = connection.execute(
            """
            SELECT
                voter_id,
                name,
                voted
            FROM voters
            ORDER BY id ASC
            """
        ).fetchall()

        counted_votes = []

        voter_status = []

        for voter in voters:

            current_voter_id = voter["voter_id"]

            latest_vote_row = connection.execute(
                """
                SELECT
                    v.id,
                    v.candidate_id,
                    v.reference_id,
                    c.candidate_name,
                    c.party_name,
                    c.symbol
                FROM votes v
                LEFT JOIN candidates c
                    ON v.candidate_id = c.id
                WHERE v.voter_id = ?
                ORDER BY v.id DESC
                LIMIT 1
                """,
                (current_voter_id,)
            ).fetchone()

            has_voted = (
                latest_vote_row is not None
            )

            latest_vote = None

            if latest_vote_row is not None:

                counted_votes.append(
                    {
                        "vote_id":
                        latest_vote_row["id"],

                        "voter_id":
                        current_voter_id,

                        "candidate_id":
                        latest_vote_row["candidate_id"]
                    }
                )

                if vote_time_column == "created_at":

                    timestamp_row = connection.execute(
                        """
                        SELECT created_at
                        FROM votes
                        WHERE id = ?
                        """,
                        (latest_vote_row["id"],)
                    ).fetchone()

                    vote_timestamp = (
                        timestamp_row["created_at"]
                        if timestamp_row is not None
                        else None
                    )

                elif vote_time_column == "timestamp":

                    timestamp_row = connection.execute(
                        """
                        SELECT timestamp
                        FROM votes
                        WHERE id = ?
                        """,
                        (latest_vote_row["id"],)
                    ).fetchone()

                    vote_timestamp = (
                        timestamp_row["timestamp"]
                        if timestamp_row is not None
                        else None
                    )

                else:

                    vote_timestamp = None

                latest_vote = {

                    "vote_id":
                    latest_vote_row["id"],

                    "candidate_id":
                    latest_vote_row["candidate_id"],

                    "candidate_name":
                    latest_vote_row["candidate_name"],

                    "party_name":
                    latest_vote_row["party_name"],

                    "symbol":
                    latest_vote_row["symbol"],

                    "reference_id":
                    latest_vote_row["reference_id"],

                    "timestamp":
                    vote_timestamp

                }

            voter_status.append(
                {

                    "voter_id":
                    current_voter_id,

                    "name":
                    voter["name"],

                    "has_voted":
                    has_voted,

                    "status":
                    (
                        "Voted"
                        if has_voted
                        else
                        "Not Voted"
                    ),

                    "latest_vote":
                    latest_vote

                }
            )

        candidate_rows = connection.execute(
            """
            SELECT
                id AS candidate_id,
                candidate_name,
                party_name,
                symbol
            FROM candidates
            ORDER BY id ASC
            """
        ).fetchall()

        candidate_vote_counts = {}

        for vote in counted_votes:

            candidate_id = vote["candidate_id"]

            candidate_vote_counts[candidate_id] = (
                candidate_vote_counts.get(
                    candidate_id,
                    0
                ) + 1
            )

        candidate_results = []

        for candidate in candidate_rows:

            candidate_id = candidate["candidate_id"]

            vote_count = int(
                candidate_vote_counts.get(
                    candidate_id,
                    0
                )
            )

            candidate_results.append(
                {

                    "candidate_id":
                    candidate_id,

                    "candidate_name":
                    candidate["candidate_name"],

                    "party_name":
                    candidate["party_name"],

                    "symbol":
                    candidate["symbol"],

                    "vote_count":
                    vote_count

                }
            )

        candidate_results.sort(
            key=lambda item: (
                -item["vote_count"],
                item["candidate_id"]
            )
        )

        total_voters = len(voters)

        total_votes = len(counted_votes)

        voted_count = len(counted_votes)

        remaining_voters = max(
            0,
            total_voters - voted_count
        )

        return {

            "success": True,

            "total_votes":
            total_votes,

            "total_voters":
            total_voters,

            "voted_voters":
            voted_count,

            "remaining_voters":
            remaining_voters,

            "candidates":
            candidate_results,

            "voters":
            voter_status

        }

    except Exception as error:

        print(
            "Admin results error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to load election results."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN DEMOGRAPHICS & ANALYTICS
# ============================================================

@app.get("/admin/analytics")
def get_admin_analytics():

    connection = get_connection()

    try:

        total_voters = connection.execute(
            """
            SELECT COUNT(*) AS count
            FROM voters
            """
        ).fetchone()["count"]

        voted_voters = connection.execute(
            """
            SELECT COUNT(DISTINCT voter_id) AS count
            FROM votes
            WHERE voter_id IN (
                SELECT voter_id
                FROM voters
            )
            """
        ).fetchone()["count"]

        not_voted_voters = max(
            0,
            total_voters - voted_voters
        )

        participation_percentage = (
            (
                voted_voters /
                total_voters
            ) * 100
            if total_voters > 0
            else 0.0
        )

        demographic_fields = [
            "district",
            "taluk",
            "block",
            "panchayat",
            "ward",
            "booth"
        ]

        voter_demographics = {}

        for field in demographic_fields:

            rows = connection.execute(
                f"""
                SELECT
                    COALESCE(
                        NULLIF(
                            TRIM({field}),
                            ''
                        ),
                        'Not Specified'
                    ) AS value,
                    COUNT(*) AS count
                FROM voters
                GROUP BY
                    COALESCE(
                        NULLIF(
                            TRIM({field}),
                            ''
                        ),
                        'Not Specified'
                    )
                ORDER BY
                    count DESC,
                    value ASC
                """
            ).fetchall()

            voter_demographics[field] = [
                {
                    "value":
                    row["value"],

                    "count":
                    row["count"]
                }
                for row in rows
            ]

        voters = connection.execute(
            """
            SELECT
                voter_id
            FROM voters
            ORDER BY id ASC
            """
        ).fetchall()

        latest_votes = []

        for voter in voters:

            voter_id = voter["voter_id"]

            latest_vote = connection.execute(
                """
                SELECT
                    v.id,
                    v.candidate_id
                FROM votes v
                WHERE v.voter_id = ?
                ORDER BY v.id DESC
                LIMIT 1
                """,
                (voter_id,)
            ).fetchone()

            if latest_vote is not None:

                latest_votes.append(
                    {
                        "voter_id":
                        voter_id,

                        "candidate_id":
                        latest_vote["candidate_id"]
                    }
                )

        candidate_rows = connection.execute(
            """
            SELECT
                id,
                candidate_name,
                party_name,
                symbol
            FROM candidates
            ORDER BY id ASC
            """
        ).fetchall()

        candidate_vote_counts = {}

        for vote in latest_votes:

            candidate_id = vote["candidate_id"]

            candidate_vote_counts[candidate_id] = (
                candidate_vote_counts.get(
                    candidate_id,
                    0
                ) + 1
            )

        total_counted_votes = len(
            latest_votes
        )

        candidate_analytics = []

        for candidate in candidate_rows:

            candidate_id = candidate["id"]

            vote_count = int(
                candidate_vote_counts.get(
                    candidate_id,
                    0
                )
            )

            vote_percentage = (
                (
                    vote_count /
                    total_counted_votes
                ) * 100
                if total_counted_votes > 0
                else 0.0
            )

            candidate_analytics.append(
                {

                    "candidate_id":
                    candidate_id,

                    "candidate_name":
                    candidate["candidate_name"],

                    "party_name":
                    candidate["party_name"],

                    "symbol":
                    candidate["symbol"],

                    "vote_count":
                    vote_count,

                    "percentage":
                    round(
                        vote_percentage,
                        2
                    )

                }
            )

        candidate_analytics.sort(
            key=lambda item: (
                -item["vote_count"],
                item["candidate_id"]
            )
        )

        verification_logs = connection.execute(
            """
            SELECT
                id,
                voter_id,
                result,
                similarity,
                threshold
            FROM verification_logs
            WHERE voter_id IN (
                SELECT voter_id
                FROM voters
            )
            ORDER BY id DESC
            """
        ).fetchall()

        latest_verification = {}

        for log in verification_logs:

            voter_id = log["voter_id"]

            if voter_id not in latest_verification:

                result = str(
                    log["result"] or ""
                ).strip().upper()

                if result in [
                    "MATCH",
                    "VERIFIED"
                ]:

                    normalized_result = "MATCH"

                elif result in [
                    "NO MATCH",
                    "FAILED",
                    "FAIL",
                    "UNVERIFIED"
                ]:

                    normalized_result = "NO MATCH"

                else:

                    similarity = (
                        log["similarity"]
                    )

                    threshold = (
                        log["threshold"]
                    )

                    if (
                        similarity is not None
                        and
                        threshold is not None
                    ):

                        try:

                            normalized_result = (
                                "MATCH"
                                if float(
                                    similarity
                                )
                                >= float(
                                    threshold
                                )
                                else
                                "NO MATCH"
                            )

                        except Exception:

                            normalized_result = (
                                "NO MATCH"
                            )

                    else:

                        normalized_result = (
                            "NO MATCH"
                        )

                latest_verification[voter_id] = (
                    normalized_result
                )

        matched_voters = sum(
            1
            for result
            in latest_verification.values()
            if result == "MATCH"
        )

        failed_voters = sum(
            1
            for result
            in latest_verification.values()
            if result == "NO MATCH"
        )

        not_tested_voters = max(
            0,
            total_voters -
            matched_voters -
            failed_voters
        )

        verification_tested = (
            matched_voters +
            failed_voters
        )

        verification_percentage = (
            (
                verification_tested /
                total_voters
            ) * 100
            if total_voters > 0
            else 0.0
        )

        return {

            "success": True,

            "voter_overview": {

                "total_voters":
                total_voters,

                "voted_voters":
                voted_voters,

                "not_voted_voters":
                not_voted_voters,

                "participation_percentage":
                round(
                    participation_percentage,
                    2
                )

            },

            "voter_demographics":
            voter_demographics,

            "participation": {

                "voted":
                voted_voters,

                "not_voted":
                not_voted_voters,

                "total":
                total_voters,

                "percentage":
                round(
                    participation_percentage,
                    2
                )

            },

            "candidate_analytics":
            candidate_analytics,

            "verification_analytics": {

                "total_voters":
                total_voters,

                "matched":
                matched_voters,

                "failed":
                failed_voters,

                "not_tested":
                not_tested_voters,

                "tested":
                verification_tested,

                "verification_percentage":
                round(
                    verification_percentage,
                    2
                )

            }

        }

    except Exception as error:

        print(
            "Admin analytics error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to load analytics data."
        )

    finally:

        connection.close()


# ============================================================
# ADMIN VISUAL CRYPTOGRAPHY
# ============================================================

@app.get("/admin/visual-cryptography")
def get_visual_cryptography():

    connection = get_connection()

    try:

        latest_votes = (
            get_latest_votes_for_registered_voters(
                connection
            )
        )

        vote_shares = []

        for vote in latest_votes:

            share_record = (
                ensure_vote_shares(
                    connection,
                    vote
                )
            )

            if share_record is None:

                continue

            share1_file = (
                BASE_DIR /
                share_record["share1_path"]
            )

            share2_file = (
                BASE_DIR /
                share_record["share2_path"]
            )

            if (
                not share1_file.exists()
                or
                not share2_file.exists()
            ):

                continue

            vote_shares.append(
                {

                    "vote_id":
                    vote["vote_id"],

                    "voter_id":
                    vote["voter_id"],

                    "voter_name":
                    vote["voter_name"],

                    "reference_id":
                    vote["reference_id"],

                    "candidate_id":
                    vote["candidate_id"],

                    "candidate_name":
                    vote["candidate_name"],

                    "party_name":
                    vote["party_name"],

                    "share_1":
                    image_to_base64(
                        share1_file
                    ),

                    "share_2":
                    image_to_base64(
                        share2_file
                    )

                }
            )

        return {

            "success": True,

            "total_voted_voters":
            len(vote_shares),

            "total_shares":
            len(vote_shares) * 2,

            "votes":
            vote_shares

        }

    except Exception as error:

        print(
            "Visual Cryptography load error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to load visual cryptography shares."
        )

    finally:

        connection.close()


# ============================================================
# COMBINE ALL VISUAL CRYPTOGRAPHY SHARES
# ============================================================

@app.post("/admin/combine-shares")
def combine_all_shares():

    connection = get_connection()

    try:

        latest_votes = (
            get_latest_votes_for_registered_voters(
                connection
            )
        )

        if not latest_votes:

            return {

                "success": True,

                "message":
                "No votes are available to combine.",

                "total_votes":
                0,

                "total_shares":
                0,

                "reconstructed_votes":
                [],

                "candidates":
                [],

                "winners":
                [],

                "winner":
                None

            }

        reconstructed_votes = []

        for vote in latest_votes:

            share_record = (
                ensure_vote_shares(
                    connection,
                    vote
                )
            )

            if share_record is None:

                raise HTTPException(
                    status_code=500,
                    detail=
                    "Vote shares could not be prepared."
                )

            share1_file = (
                BASE_DIR /
                share_record["share1_path"]
            )

            share2_file = (
                BASE_DIR /
                share_record["share2_path"]
            )

            if (
                not share1_file.exists()
                or
                not share2_file.exists()
            ):

                raise HTTPException(
                    status_code=500,
                    detail=
                    "One or more vote shares are missing."
                )

            share1_image = (
                load_share_image(
                    share1_file
                )
            )

            share2_image = (
                load_share_image(
                    share2_file
                )
            )

            combined_image = (
                combine_share_images(
                    share1_image,
                    share2_image
                )
            )

            decoded_candidate_id = (
                decode_candidate_id(
                    combined_image
                )
            )

            if (
                decoded_candidate_id
                !=
                int(vote["candidate_id"])
            ):

                raise HTTPException(
                    status_code=500,
                    detail=(
                        "Visual cryptography reconstruction "
                        "does not match the stored vote."
                    )
                )

            reconstructed_votes.append(
                {

                    "vote_id":
                    vote["vote_id"],

                    "voter_id":
                    vote["voter_id"],

                    "voter_name":
                    vote["voter_name"],

                    "reference_id":
                    vote["reference_id"],

                    "candidate_id":
                    decoded_candidate_id,

                    "candidate_name":
                    vote["candidate_name"],

                    "party_name":
                    vote["party_name"],

                    "symbol":
                    vote["symbol"]

                }
            )

        candidate_rows = connection.execute(
            """
            SELECT
                id,
                candidate_name,
                party_name,
                symbol
            FROM candidates
            ORDER BY id ASC
            """
        ).fetchall()

        candidate_counts = {}

        for vote in reconstructed_votes:

            candidate_id = (
                int(
                    vote["candidate_id"]
                )
            )

            candidate_counts[candidate_id] = (
                candidate_counts.get(
                    candidate_id,
                    0
                ) + 1
            )

        candidate_results = []

        for candidate in candidate_rows:

            candidate_id = (
                int(
                    candidate["id"]
                )
            )

            vote_count = int(
                candidate_counts.get(
                    candidate_id,
                    0
                )
            )

            candidate_results.append(
                {

                    "candidate_id":
                    candidate_id,

                    "candidate_name":
                    candidate["candidate_name"],

                    "party_name":
                    candidate["party_name"],

                    "symbol":
                    candidate["symbol"],

                    "vote_count":
                    vote_count

                }
            )

        candidate_results.sort(
            key=lambda item: (
                -item["vote_count"],
                item["candidate_id"]
            )
        )

        total_votes = len(
            reconstructed_votes
        )

        winners = []

        if total_votes > 0:

            highest_vote_count = max(
                item["vote_count"]
                for item in candidate_results
            )

            if highest_vote_count > 0:

                winners = [
                    item
                    for item in candidate_results
                    if item["vote_count"]
                    == highest_vote_count
                ]

        winner = None

        if len(winners) == 1:

            winner = winners[0]

        elif len(winners) > 1:

            winner = {

                "tie": True,

                "vote_count":
                winners[0]["vote_count"],

                "candidates":
                winners

            }

        return {

            "success": True,

            "message":
            "All vote shares combined successfully.",

            "total_votes":
            total_votes,

            "total_shares":
            total_votes * 2,

            "reconstructed_votes":
            reconstructed_votes,

            "candidates":
            candidate_results,

            "winners":
            winners,

            "winner":
            winner

        }

    except HTTPException:

        raise

    except Exception as error:

        print(
            "Visual Cryptography combine error:",
            error
        )

        raise HTTPException(
            status_code=500,
            detail=
            "Unable to combine visual cryptography shares."
        )

    finally:

        connection.close()


# ============================================================
# STARTUP INFORMATION
# ============================================================

print()
print(
    "============================================================"
)

print(
    "SMARTPOLL BACKEND READY"
)

print(
    "============================================================"
)

print(
    "Database       :",
    DB_PATH
)

print(
    "Dataset        :",
    DATASET_DIR
)

print(
    "Vote Shares    :",
    SHARES_DIR
)

print(
    "Face Model     : InsightFace buffalo_l"
)

print(
    "Face Threshold :",
    FACE_THRESHOLD
)

print(
    "Admin Model    : ADMIN001"
)

print(
    "Admin Dataset  : "
    "ADMIN001/embeddings.pkl"
)

print(
    "Admin Candidates API : "
    "/admin/candidates"
)

print(
    "Admin Voters API     : "
    "/admin/voters"
)

print(
    "Add Voter API        : "
    "/admin/voters/add"
)

print(
    "Remove Voter API     : "
    "/admin/voters/{voter_id}"
)

print(
    "Add Candidate API    : "
    "/admin/candidates/add"
)

print(
    "Remove Candidate API : "
    "/admin/candidates/{candidate_id}"
)

print(
    "Admin Dashboard API  : "
    "/admin/dashboard"
)

print(
    "Admin Analytics API  : "
    "/admin/analytics"
)

print(
    "Admin Results API    : "
    "/admin/results"
)

print(
    "Verification Logs   : "
    "/verification-logs"
)

print(
    "Visual Crypto API   : "
    "/admin/visual-cryptography"
)

print(
    "Combine Shares API  : "
    "/admin/combine-shares"
)

print(
    "============================================================"
)

print()
