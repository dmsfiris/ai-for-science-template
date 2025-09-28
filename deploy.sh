#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
DEFAULT_COMPOSE_FILES=("docker-compose.yml" "docker-compose.override.yml")

BASE_PATH="${BASE_PATH:-/ai-for-science}"
API_LOCAL="http://127.0.0.1:8001"
FRONT_LOCAL="http://127.0.0.1:3001"
DOMAIN="${DOMAIN:-$(grep -E '^DOMAIN=' "$PROJECT_DIR/.env" 2>/dev/null | cut -d= -f2 || true)}"
API_PUBLIC="${API_PUBLIC:-https://api.${DOMAIN}${BASE_PATH}}"
FRONT_PUBLIC="${FRONT_PUBLIC:-https://${DOMAIN}${BASE_PATH}}"

die(){ echo "ERROR: $*" >&2; exit 1; }
usage(){ cat <<'H'
Usage:
  deploy.sh [-f file.yml ...] <command> [options] [service...]
Commands:
  up [--build] [--no-cache] [--pull] [service...] 
  build [--no-cache] [--pull] [service...]
  restart [service...]
  down [--remove-orphans] [--with-volumes]
  ps
  logs [-f] [service]
  prune [images|builder|all]
  check [local|public|all]
H
}

COMPOSE_FILES=()
while (( $# )); do
  case "${1:-}" in
    -f) shift; [[ $# -gt 0 ]] || die "-f needs a file"; COMPOSE_FILES+=("$1"); shift ;;
    -h|--help) usage; exit 0 ;;
    *) break ;;
  esac
done

CMD="${1:-up}"; shift || true

cd "$PROJECT_DIR" || die "Project dir not found: $PROJECT_DIR"
if [[ ${#COMPOSE_FILES[@]} -eq 0 ]]; then COMPOSE_FILES=("${DEFAULT_COMPOSE_FILES[@]}"); fi
COMPOSE=( docker compose )
for f in "${COMPOSE_FILES[@]}"; do
  [[ -f "$f" ]] || die "Compose file not found: $f"
  COMPOSE+=(-f "$f")
done

case "$CMD" in
  up)
    BUILD=0; NOCACHE=0; PULL=0; ARGS=()
    while (( $# )); do
      case "$1" in
        --build) BUILD=1; shift ;;
        --no-cache) NOCACHE=1; shift ;;
        --pull) PULL=1; shift ;;
        *) ARGS+=("$1"); shift ;;
      esac
    done
    [[ $PULL -eq 1 ]] && "${COMPOSE[@]}" pull || true
    if [[ $BUILD -eq 1 || $NOCACHE -eq 1 ]]; then
      [[ $NOCACHE -eq 1 ]] && "${COMPOSE[@]}" build --no-cache "${ARGS[@]}" || "${COMPOSE[@]}" build "${ARGS[@]}"
    fi
    "${COMPOSE[@]}" up -d "${ARGS[@]}"
    "${COMPOSE[@]}" ps
    ;;
  build)
    NOCACHE=0; PULL=0; SRV=()
    while (( $# )); do
      case "$1" in
        --no-cache) NOCACHE=1; shift ;;
        --pull) PULL=1; shift ;;
        *) SRV+=("$1"); shift ;;
      esac
    done
    [[ $PULL -eq 1 ]] && "${COMPOSE[@]}" pull "${SRV[@]}" || true
    [[ $NOCACHE -eq 1 ]] && "${COMPOSE[@]}" build --no-cache "${SRV[@]}" || "${COMPOSE[@]}" build "${SRV[@]}"
    ;;
  restart) "${COMPOSE[@]}" restart "$@" ;;
  down)
    REMOVE_ORPHANS=0; WITH_VOLUMES=0
    while (( $# )); do
      case "$1" in
        --remove-orphans) REMOVE_ORPHANS=1; shift ;;
        --with-volumes) WITH_VOLUMES=1; shift ;;
        *) die "Unknown option for down: $1" ;;
      esac
    done
    args=(down); [[ $REMOVE_ORPHANS -eq 1 ]] && args+=(--remove-orphans); [[ $WITH_VOLUMES -eq 1 ]] && args+=(-v)
    "${COMPOSE[@]}" "${args[@]}"
    ;;
  ps) "${COMPOSE[@]}" ps ;;
  logs)
    FOLLOW=0; [[ "${1:-}" == "-f" ]] && FOLLOW=1 && shift
    [[ $FOLLOW -eq 1 ]] && "${COMPOSE[@]}" logs -f "$@" || "${COMPOSE[@]}" logs --tail=200 "$@"
    ;;
  prune)
    MODE="${1:-images}"
    case "$MODE" in
      images)  docker image prune -f ;;
      builder) docker builder prune -f ;;
      all)     docker image prune -a -f; docker builder prune -f ;;
      *) echo "Unknown prune mode: $MODE" ;;
    esac
    docker system df
    ;;
  check)
    WHAT="${1:-all}"
    command -v curl >/dev/null || die "curl is required"
    case "$WHAT" in
      local|all)
        echo "LOCAL API:  $API_LOCAL/api/v1/healthz";  curl -sS "$API_LOCAL/api/v1/healthz" || true; echo
        echo "LOCAL UI:   $FRONT_LOCAL$BASE_PATH/";    curl -I "$FRONT_LOCAL$BASE_PATH/" || true; echo ;;
    esac
    case "$WHAT" in
      public|all)
        if [[ -z "${DOMAIN:-}" ]]; then echo "DOMAIN not set — skipping public checks."; else
          echo "PUBLIC API:  https://api.${DOMAIN}${BASE_PATH}/api/v1/healthz"; curl -sS "https://api.${DOMAIN}${BASE_PATH}/api/v1/healthz" || true; echo
          echo "PUBLIC UI:   https://${DOMAIN}${BASE_PATH}/";                   curl -I  "https://${DOMAIN}${BASE_PATH}/" || true; echo
        fi ;;
    esac
    ;;
  *) usage; exit 1 ;;
esac

