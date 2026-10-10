import sqlite3
import os

DATABASE = os.path.join(
    os.path.dirname(__file__),
    "smartpoll.db"
)

# ============================================================
# MEMBER DETAILS
# ============================================================

members = [
    ("SPV001", "Elavarasi"),
    ("SPV002", "Gowri"),
    ("SPV003", "Amutha"),
    ("SPV004", "Amirtha Lakshmi"),
    ("SPV005", "Susmitha Sri"),
    ("SPV006", "Maheswari"),
    ("SPV007", "Esakkiammal"),
    ("SPV008", "Jaycee"),
    ("SPV009", "Vikashini"),
]


# ============================================================
# DATABASE CONNECTION
# ============================================================

connection = sqlite3.connect(DATABASE)
cursor = connection.cursor()


# ============================================================
# UPDATE EACH MEMBER
# ============================================================

print("\nSmartPoll - Update Registered Phone Numbers")
print("-------------------------------------------\n")

for voter_id, name in members:

    while True:

        phone = input(
            f"Enter registered phone for "
            f"{voter_id} - {name}: "
        ).strip()

        # Basic validation
        if phone.isdigit() and len(phone) >= 10:
            break

        print(
            "Invalid phone number. "
            "Please enter a valid number.\n"
        )

    cursor.execute(
        """
        UPDATE voters
        SET name = ?, phone = ?
        WHERE voter_id = ?
        """,
        (
            name,
            phone,
            voter_id
        )
    )

    if cursor.rowcount == 1:
        print(
            f"{voter_id} updated successfully.\n"
        )
    else:
        print(
            f"{voter_id} was not found in database.\n"
        )


# ============================================================
# SAVE CHANGES
# ============================================================

connection.commit()
connection.close()


print("-------------------------------------------")
print("All 9 member details updated successfully.")
print("Phone numbers are stored in the local database.")
print("-------------------------------------------")