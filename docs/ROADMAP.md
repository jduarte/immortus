ROADMAP
---

#### 0.0.1

- [x] Tests
- [x] Routes DSL ( immortus_jobs )
- [x] Immortus JavaScript ( polling )
- [x] Default verify ( ImmortusController#verify )
- [x] Tracking Strategies
    - [x] Delayed Job ( AR )

#### Soon

- [ ] Setup testing environment to work with different Ruby versions and Rails versions
- [ ] Tests
    - [ ] Tracking Strategies
        - [ ] Backburner
        - [ ] Qu
        - [ ] Que
        - [ ] queue_classic
        - [ ] Resque
        - [ ] Sidekiq
        - [ ] Sneakers
        - [ ] Sucker Punch
        - [ ] Active Job Inline
- [ ] Tracking Strategies
    - [ ] Backburner
    - [ ] Qu
    - [ ] Que
    - [ ] queue_classic
    - [ ] Resque
    - [ ] Sidekiq
    - [ ] Sneakers
    - [ ] Sucker Punch
    - [ ] Active Job Inline
- [ ] Ensure JavaScript callbacks `data` is available
- [ ] LOGS

#### Future Developments

- [ ] Error handling: http://www.sitepoint.com/dont-get-activejob/
- [ ] How to handle jobs that are divided into multiple sub-jobs
- [ ] WebSockets support
    - [ ] ActionCable support
- [ ] Consider remove ActiveJob dependency ( support using Backends directly "Delayed Job", "Sidekiq", etc )
- [ ] Consider remove Rails dependency
