import json
import socket
import uuid
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path

from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI()

class Storage(str, Enum):
    ebs = "ebs"
    efs = "efs"

# Where the chart mounts each volume
DATA_DIRS = {
    Storage.ebs: "/data/ebs",
    Storage.efs: "/data/efs",
}

class OrderIn(BaseModel):
    item: str
    quantity: int = Field(gt=0)

class Order(OrderIn):
    id: str
    created_at: datetime
    created_by: str  # the pod's hostname - with EFS, pods see each other's orders

def orders_dir(storage: Storage) -> Path:
    path = Path(DATA_DIRS[storage]) / "orders"
    path.mkdir(exist_ok=True)
    return path

@app.get("/")
def read_root():
    return {"message": "Hello, World!"}

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

# These endppoints demonstrate connection to EBS/EFS storage
@app.post("/orders/{storage}", status_code=201)
def create_order(storage: Storage, order_in: OrderIn) -> Order:
    order = Order(
        **order_in.model_dump(),
        id=str(uuid.uuid4()),
        created_at=datetime.now(timezone.utc),
        created_by=socket.gethostname(),
    )
    (orders_dir(storage) / f"{order.id}.json").write_text(order.model_dump_json())
    return order


@app.get("/orders/{storage}")
def list_orders(storage: Storage) -> list[Order]:
    orders = [Order(**json.loads(f.read_text())) for f in orders_dir(storage).glob("*.json")]
    return sorted(orders, key=lambda o: o.created_at)
