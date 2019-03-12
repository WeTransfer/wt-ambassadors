# A DNS record for easy reading
resource "aws_route53_record" "dns-record" {
  zone_id = "${data.aws_route53_zone.wetransfer.id}"
  name    = "ambassadors.${local.tlds[local.workspace_prefix]}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.origin.website_domain}"
    zone_id                = "${aws_s3_bucket.origin.hosted_zone_id}"
    evaluate_target_health = false
  }
}

# The bucket holding and serving our files
resource "aws_s3_bucket" "origin" {
  bucket = "ambassadors.${local.tlds[local.workspace_prefix]}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_iam_user" "forestry" {
  name = "${local.prefix}-forestry"
}

# Who can do what with our bucket?
resource "aws_s3_bucket_policy" "office-only" {
  bucket = "${aws_s3_bucket.origin.id}"

  policy = <<POLICY
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.origin.arn}/*",
      "Principal": "*",
      "Action": "s3:*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "46.244.105.58/32"
        }
      }
    },
    {
      "Sid": "2",
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.origin.arn}/*",
      "Principal": {
        "AWS": ["${aws_iam_user.forestry.arn}"]
      },
      "Action": "s3:*"
    }
  ]
}
POLICY
}

# We also need to allow the user to access the bucket
resource "aws_iam_user_policy_attachment" "user-s3-attach" {
  user       = "${aws_iam_user.forestry.name}"
  policy_arn = "${aws_iam_policy.s3-access.arn}"
}

resource "aws_iam_policy" "s3-access" {
  name = "${local.prefix}-user-access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
          "${aws_s3_bucket.origin.arn}/*"
      ]
    },
    {
      "Sid": "2",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "${aws_s3_bucket.origin.arn}"
    }
  ]
}
EOF
}
