from enum import Enum

class APIType(Enum):
    REST = "REST"
    SOAP = "SOAP"
    GraphQL = "GraphQL"
    Unknown = "Unknown"
