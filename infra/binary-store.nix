{ }:
let
  region = "eu-west-2";
  accessKeyId = "default";
  project = "future-is-coming-worker-binary-store"; # would be good to take it from config
in
{
  # TODO add tags
  resources.s3Buckets."${project}" =
    {
      inherit region accessKeyId;
      name = project;
      versioning = "Suspended";
      policy = ''
      {
        "Id": "DirectReads",
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowDirectReads",
                "Action": [
                    "s3:GetObject",
                    "s3:GetBucketLocation"
                ],
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:s3:::${project}",
                    "arn:aws:s3:::${project}/*"
                ],
                "Principal": "*"
            }
        ]
      }
      '';
    };

  resources.iam-role."${project}-iam-role" = 
  {
    inherit accessKeyId;
    policy = ''
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "UploadToCache",
          "Effect": "Allow",
          "Action": [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:ListMultipartUploadParts",
            "s3:ListAllMyBuckets",
            "s3:PutObject"
          ],
          "Resource": [
            "arn:aws:s3:::${project}",
            "arn:aws:s3:::${project}/*"
          ]
        }
      ]
    }
    '';
  }
}