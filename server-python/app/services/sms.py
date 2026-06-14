"""SMS service — abstraction over SMS providers.

支持 mock、阿里云短信、Twilio 等。
当前默认使用 mock provider（开发阶段）。
"""

import random
import logging
from abc import ABC, abstractmethod

from app.config import settings

logger = logging.getLogger(__name__)


class SMSProvider(ABC):
    """SMS 发送抽象基类"""

    @abstractmethod
    async def send_code(self, country_code: str, phone: str, code: str) -> bool:
        """发送验证码。返回是否成功。"""
        ...


class MockSMSProvider(SMSProvider):
    """开发阶段 mock provider — 打印验证码到日志，始终返回成功。"""

    async def send_code(self, country_code: str, phone: str, code: str) -> bool:
        logger.info(f"[MOCK SMS] To: {country_code}{phone}  Code: {code}")
        return True


class AliyunSMSProvider(SMSProvider):
    """阿里云短信服务（待实现）"""

    async def send_code(self, country_code: str, phone: str, code: str) -> bool:
        # TODO: 接入阿里云短信 SDK
        logger.warning("Aliyun SMS not yet implemented; falling back to mock")
        return await MockSMSProvider().send_code(country_code, phone, code)


class TwilioSMSProvider(SMSProvider):
    """Twilio 短信服务 — 用于国际短信（待实现）"""

    async def send_code(self, country_code: str, phone: str, code: str) -> bool:
        # TODO: 接入 Twilio SDK
        logger.warning("Twilio SMS not yet implemented; falling back to mock")
        return await MockSMSProvider().send_code(country_code, phone, code)


def get_sms_provider() -> SMSProvider:
    """根据配置返回合适的 SMS provider。"""
    provider_name = settings.SMS_PROVIDER
    if provider_name == "aliyun":
        return AliyunSMSProvider()
    elif provider_name == "twilio":
        return TwilioSMSProvider()
    else:
        return MockSMSProvider()


def generate_code(length: int = 6) -> str:
    """生成随机数字验证码。"""
    return "".join(str(random.randint(0, 9)) for _ in range(length))
