import psycopg2
from faker import Faker
from concurrent.futures import ThreadPoolExecutor
import random

# Configuração do Faker para geração de dados fictícios
fake = Faker()

# Funções para gerar dados fictícios para cada tabela
def generate_cliente():
    nome = fake.name()
    email = fake.email()
    telefone = fake.phone_number()
    endereco = fake.address()

    # Truncar o número de telefone para 20 caracteres, se necessário
    if len(telefone) > 20:
        telefone = telefone[:20]

    return (nome, email, telefone, endereco)

def generate_item():
    return (fake.word(), fake.text(), round(random.uniform(10, 1000), 2))

def generate_pedido(cliente_ids):
    return (random.choice(cliente_ids), round(random.uniform(100, 2000), 2))

def generate_item_pedido(pedido_ids, item_ids):
    return (random.choice(pedido_ids), random.choice(item_ids), random.randint(1, 10))

# Função para inserir dados nas tabelas
def populate_db(n_clientes=10, n_itens=30, user='', password='', database=''):
    conn = psycopg2.connect(host='localhost', port='5432', dbname=database, user=user, password=password)
    cur = conn.cursor()

    cliente_ids = []
    for _ in range(n_clientes):
        data = generate_cliente()
        cur.execute("INSERT INTO clientes (nome, email, telefone, endereco) VALUES (%s, %s, %s, %s) RETURNING id", data)
        cliente_ids.append(cur.fetchone()[0])

    item_ids = []
    for _ in range(n_itens):
        data = generate_item()
        cur.execute("INSERT INTO itens (nome, descricao, preco) VALUES (%s, %s, %s) RETURNING id", data)
        item_ids.append(cur.fetchone()[0])

    pedido_ids = []
    with ThreadPoolExecutor(max_workers=5) as executor:
        results = executor.map(lambda _: generate_pedido(cliente_ids), range(20))
        for data in results:
            cur.execute("INSERT INTO pedidos (cliente_id, valor_total) VALUES (%s, %s) RETURNING id", data)
            pedido_ids.append(cur.fetchone()[0])

    # Evitar duplicatas ao inserir em itens_pedidos
    inserted_pairs = set()
    with ThreadPoolExecutor(max_workers=5) as executor:
        results = executor.map(lambda _: generate_item_pedido(pedido_ids, item_ids), range(100))
        for data in results:
            if (data[0], data[1]) not in inserted_pairs:
                cur.execute("INSERT INTO itens_pedidos (pedido_id, item_id, quantidade) VALUES (%s, %s, %s)", data)
                inserted_pairs.add((data[0], data[1]))

    conn.commit()
    cur.close()
    conn.close()

if __name__ == '__main__':
    populate_db(n_clientes=10, n_itens=30, user='admin', password='admin', database='mydatabase')
