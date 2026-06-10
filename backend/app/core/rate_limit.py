import time
import redis
from app.core.config import settings

_r = redis.from_url(settings.REDIS_URL)


def rate_limit_hit(bucket: str, max_per_min: int) -> bool:
    """
    returns True if allowed, False if limited
    bucket: e.g., "preauth:ip:1.2.3.4" or "signin:email:foo@bar"
    """
    key = f"rl:{bucket}"
    now_min = int(time.time() // 60)
    pipe = _r.pipeline()
    pipe.zremrangebyscore(key, 0, now_min - 1)
    pipe.zincrby(key, 1, now_min)
    pipe.zrange(key, 0, -1, withscores=True)
    pipe.expire(key, 120)
    _, _, entries, _ = pipe.execute()
    # sum counts for current minute only
    total_now = 0
    for member, score in entries:
        if int(score) == now_min:
            total_now += int(float(_r.zscore(key, member)) or 0)
    return total_now <= max_per_min
