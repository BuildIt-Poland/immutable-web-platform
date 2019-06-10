#!/usr/bin/env node
import 'source-map-support/register';
import cdk = require('@aws-cdk/cdk');
import { AwsStack } from '../lib/aws-stack';

const app = new cdk.App();
new AwsStack(app, 'AwsStack');
