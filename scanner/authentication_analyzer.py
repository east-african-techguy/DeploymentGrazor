# *Version: 1.3.0*
# *Author: API Scanner Team*
# *Date: 2024-07-30*

"""Analyzes discovered APIs for authentication requirements."""

import logging
from typing import Dict, Any, Optional, Tuple, List
from urllib.parse import urlparse, urlunparse, urljoin

import requests
from requests.exceptions import RequestException
from requests.structures import CaseInsensitiveDict
import urllib3
from .classifier import APIType

log = logging.getLogger(__name__)

# Authentication result constants
AUTH_REQUIRED = "required"
AUTH_NONE = "none"
AUTH_UNKNOWN = "unknown"
AUTH_ERROR = "error"

# Schemes
SCHEME_BASIC = "Basic"
SCHEME_BEARER = "Bearer"
SCHEME_DIGEST = "Digest"
SCHEME_OAUTH = "OAuth"

COMMON_AUTH_PATHS: List[str] = [
    "/login",
    "/logon",
    "/signin",
    "/auth",
    "/authenticate",
    "/oauth/authorize",
    "/oauth2/authorize",
    "/connect/authorize",
    "/identity",
    "/account/login",
    "/api/auth/login",
    "/.well-known/openid-configuration",
]

REDIRECT_AUTH_KEYWORDS = [
    "login",
    "logon",
    "signin",
    "auth",
    "sso",
    "oauth",
    "oidc",
    "saml",
    "account",
    "identity",
]


class AuthenticationAnalyzer:
    """Check if an API endpoint requires authentication."""

    def __init__(self, timeout: float = 5.0, user_agent: Optional[str] = None):
        self.timeout = timeout
        self.session = requests.Session()
        if user_agent:
            self.session.headers.update({"User-Agent": user_agent})
        self.session.allow_redirects = False
        self.soap_headers = self.session.headers.copy()
        self.soap_headers["Content-Type"] = "text/xml; charset=utf-8"
        self.session.verify = False
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    def analyze(
        self, api_info: Dict[str, Any], api_type: APIType = APIType.Unknown
    ) -> Tuple[str, Optional[str], Optional[int], Optional[str]]:
        url = api_info.get("url")
        if not url:
            log.warning("Cannot analyze authentication without URL in api_info.")
            return AUTH_UNKNOWN, None, None, None

        probe_method: Optional[str] = None
        probe_status_code: Optional[int] = None
        direct_check_auth_status = AUTH_UNKNOWN
        direct_check_auth_details: Optional[str] = None

        try:
            if api_type == APIType.SOAP:
                probe_method = "POST"
                soap_body = (
                    "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                    "<soap:Body/></soap:Envelope>"
                ).encode("utf-8")
                req_kwargs = {"data": soap_body, "headers": self.soap_headers}
            else:
                probe_method = "GET"
                req_kwargs = {}

            response = self.session.request(
                probe_method, url, timeout=self.timeout, **req_kwargs
            )
            headers = CaseInsensitiveDict(response.headers)
            probe_status_code = response.status_code

            if probe_status_code == 401:
                www_authenticate = headers.get("WWW-Authenticate")
                scheme = self._parse_www_authenticate(www_authenticate)
                direct_check_auth_status = AUTH_REQUIRED
                direct_check_auth_details = scheme
            elif probe_status_code == 403:
                direct_check_auth_status = AUTH_REQUIRED
                direct_check_auth_details = "Forbidden (403)"
            elif response.is_redirect:
                location = headers.get("Location")
                redirect_detail = self._analyze_redirect_location(location)
                direct_check_auth_status = AUTH_REQUIRED
                direct_check_auth_details = redirect_detail
            elif probe_status_code < 400:
                direct_check_auth_status = AUTH_NONE

        except RequestException as e:
            direct_check_auth_status = AUTH_ERROR
            direct_check_auth_details = f"Direct check error: {type(e).__name__}"
        except Exception as e:
            direct_check_auth_status = AUTH_ERROR
            direct_check_auth_details = f"Direct check error: {type(e).__name__}"

        if direct_check_auth_status == AUTH_REQUIRED:
            return (
                direct_check_auth_status,
                direct_check_auth_details,
                probe_status_code,
                probe_method,
            )

        common_path_auth_status = AUTH_UNKNOWN
        common_path_auth_details: Optional[str] = None
        try:
            base_url = self._get_base_url(url)
            if base_url:
                for path in COMMON_AUTH_PATHS:
                    check_url = urljoin(base_url, path)
                    if check_url == url:
                        continue
                    exists, status, redirect_loc = self._check_path_existence(check_url)
                    if exists:
                        detail = f"Common Path Found: {path} (Status: {status})"
                        if redirect_loc:
                            redirect_detail = self._analyze_redirect_location(redirect_loc)
                            detail = f"Common Path Found: {path} ({redirect_detail})"
                        common_path_auth_status = AUTH_REQUIRED
                        common_path_auth_details = detail
                        break
        except Exception as e:
            if direct_check_auth_status != AUTH_ERROR:
                return (
                    AUTH_ERROR,
                    f"Error checking common paths: {type(e).__name__}",
                    probe_status_code,
                    probe_method,
                )

        if common_path_auth_status == AUTH_REQUIRED:
            return (
                common_path_auth_status,
                common_path_auth_details,
                probe_status_code,
                probe_method,
            )
        elif direct_check_auth_status == AUTH_ERROR:
            return (
                direct_check_auth_status,
                direct_check_auth_details,
                probe_status_code,
                probe_method,
            )
        elif direct_check_auth_status == AUTH_NONE:
            return (
                direct_check_auth_status,
                direct_check_auth_details,
                probe_status_code,
                probe_method,
            )
        else:
            return AUTH_NONE, None, probe_status_code, probe_method

    def _check_path_existence(
        self, url: str
    ) -> Tuple[bool, Optional[int], Optional[str]]:
        try:
            response = self.session.head(url, timeout=self.timeout / 2)
            if response.status_code < 400:
                return True, response.status_code, response.headers.get("Location")
            elif response.status_code in [401, 403, 405]:
                return True, response.status_code, None
            else:
                return False, response.status_code, None
        except RequestException as head_err:
            if any(code in str(head_err) for code in ["405", "501", "400"]):
                try:
                    response = self.session.get(url, timeout=self.timeout)
                    if response.status_code < 400:
                        return (
                            True,
                            response.status_code,
                            response.headers.get("Location"),
                        )
                    elif response.status_code in [401, 403]:
                        return True, response.status_code, None
                    else:
                        return False, response.status_code, None
                except RequestException:
                    return False, None, None
            else:
                return False, None, None
        except Exception:
            return False, None, None

    def _analyze_redirect_location(self, location: Optional[str]) -> str:
        if not location:
            return "Redirect Detected (No Location)"
        detail = f"Redirect Detected ({location})"
        try:
            location_lower = location.lower()
            parsed_location = urlparse(location)
            path_query = (parsed_location.path + "?" + parsed_location.query).lower()
            for keyword in REDIRECT_AUTH_KEYWORDS:
                if keyword in path_query:
                    detail = f"Redirect to Auth Path ({location})"
                    break
        except Exception:
            pass
        return detail

    def _get_base_url(self, url: str) -> Optional[str]:
        try:
            parsed = urlparse(url)
            if not parsed.scheme or not parsed.netloc:
                return None
            return urlunparse((parsed.scheme, parsed.netloc, "", "", "", ""))
        except Exception:
            return None

    def _parse_www_authenticate(self, header_value: Optional[str]) -> Optional[str]:
        if not header_value:
            return None
        try:
            challenges = header_value.split(",")
            first_challenge = challenges[0].strip()
            scheme = first_challenge.split(" ")[0]
            if scheme.lower() == "basic":
                return SCHEME_BASIC
            elif scheme.lower() == "bearer":
                return SCHEME_BEARER
            elif scheme.lower() == "digest":
                return SCHEME_DIGEST
            elif SCHEME_OAUTH.lower() in scheme.lower():
                return SCHEME_OAUTH
            return scheme.capitalize() if scheme else None
        except Exception:
            return None

    def __del__(self):
        if hasattr(self, "session") and self.session:
            self.session.close()
