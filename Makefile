.PHONY: up down logs build fmt

up:
	docker compose up --build

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=200

build:
	docker compose build

fmt:
	@echo "No formatters yet. We'll add ruff/mypy/eslint in Step 2."
