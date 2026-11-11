"""add_admin_approval_and_supervisor

Revision ID: e7bae8996654
Revises: 697ab56ce857
Create Date: 2026-11-11 20:42:37.292491

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e7bae8996654'
down_revision: Union[str, Sequence[str], None] = '697ab56ce857'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        'administrators',
        sa.Column('approval_status', sa.String(length=50), nullable=False, server_default='APPROVED')
    )
    op.add_column(
        'administrators',
        sa.Column('signup_source', sa.String(length=50), nullable=False, server_default='EMAIL')
    )
    op.create_index(op.f('ix_administrators_approval_status'), 'administrators', ['approval_status'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_administrators_approval_status'), table_name='administrators')
    op.drop_column('administrators', 'signup_source')
    op.drop_column('administrators', 'approval_status')
