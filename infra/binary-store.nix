{ }:
let
  region = "eu-west-2";
  accessKeyId = "default";
  project = "future-is-coming-binary-store"; # would be good to take it from config
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
          "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "testing",
              "Effect": "Allow",
              "Principal": "*",
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::${project}/*"
            }
          ]
        }
        '';
       lifeCycle = ''
         {
           "Rules": [
              {
                "Status": "Enabled",
                "Prefix": "",
                "Transitions": [
                  {
                    "Days": 30,
                    "StorageClass": "GLACIER"
                  }
                ],
                "ID": "Glacier",
                "AbortIncompleteMultipartUpload":
                  {
                    "DaysAfterInitiation": 7
                  }
              }
           ]
         }
       '';
    };
}