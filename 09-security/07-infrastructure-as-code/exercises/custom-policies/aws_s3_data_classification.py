from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult


class S3DataClassification(BaseResourceCheck):
    def __init__(self):
        super().__init__(
            name="S3 buckets must carry data_classification tag",
            id="CKV_CUSTOM_S3_TAG_DC",
            categories=[CheckCategories.GENERAL_SECURITY],
            supported_resources=["aws_s3_bucket"],
        )

    def scan_resource_conf(self, conf):
        tags_conf = conf.get("tags", [{}])
        tags = tags_conf[0] if isinstance(tags_conf, list) else tags_conf
        if isinstance(tags, dict) and "data_classification" in tags:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = S3DataClassification()
