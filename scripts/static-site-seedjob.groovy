multibranchPipelineJob('Static Site') {
  branchSources {
    github {
      id('static-site-job')
      scanCredentialsId('GITHUB_CREDENTIALS')
      repoOwner('Harshithhk')
      repository('notepad-static-site')
    }
  }

  orphanedItemStrategy {
    discardOldItems {
      numToKeep(-1)
      daysToKeep(-1)
    }
  }
}
