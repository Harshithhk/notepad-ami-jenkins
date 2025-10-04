multibranchPipelineJob('Static Site') {
  branchSources {
    github {
      id('team08-static-site')
      scanCredentialsId('GITHUB_CREDENTIALS')
      repoOwner('csye7125-su24-team08')
      repository('static-site')
    }
  }

  orphanedItemStrategy {
    discardOldItems {
      numToKeep(-1)
      daysToKeep(-1)
    }
  }
}
