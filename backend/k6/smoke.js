import http from 'k6/http';
import { check } from 'k6';

export const options = { vus: 1, duration: '30s' };

export default function () {
  const url = `${__ENV.API_URL}/api/v1/healthz`;
  const res = http.get(url);
  check(res, { 'status 200': (r) => r.status === 200 });
}
