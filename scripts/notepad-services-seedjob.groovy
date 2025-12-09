multibranchPipelineJob('Static Site') {
  branchSources {
    github {
      id('notepad-services-job')
      scanCredentialsId('GITHUB_CREDENTIALS')
      repoOwner('Harshithhk')
      repository('notepad-services')
    }
  }

  orphanedItemStrategy {
    discardOldItems {
      numToKeep(-1)
      daysToKeep(-1)
    }
  }
}
