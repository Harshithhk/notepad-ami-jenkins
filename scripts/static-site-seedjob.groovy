multibranchPipelineJob('Static Site') {
  branchSources {
    github {
      id('static-site-job')
      scanCredentialsId('GITHUB_CREDENTIALS')
      repoOwner('Harshithhk')
      repository('whiteboard-static-site')
    }
  }

  orphanedItemStrategy {
    discardOldItems {
      numToKeep(-1)
      daysToKeep(-1)
    }
  }
}
