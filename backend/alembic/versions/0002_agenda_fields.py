"""add agenda and AI suggestion JSON fields"""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("meetings", sa.Column("agenda", sa.JSON(), nullable=True))
    op.add_column("meetings", sa.Column("ai_suggestion", sa.JSON(), nullable=True))


def downgrade() -> None:
    op.drop_column("meetings", "ai_suggestion")
    op.drop_column("meetings", "agenda")
