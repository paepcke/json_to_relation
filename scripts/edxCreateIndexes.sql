CREATE INDEX EdxTrackEventIdxEvType
       ON Edx.EdxTrackEvent(event_type(255));

CREATE INDEX EdxTrackEventIdxUname
       ON Edx.EdxTrackEvent(anon_screen_name(255));

CREATE INDEX EdxTrackEventIdxCourseID
       ON Edx.EdxTrackEvent(course_id(255));

CREATE INDEX EdxTrackEventIdxSeqID
       ON Edx.EdxTrackEvent(sequence_id(255));

CREATE INDEX EdxTrackEventIdxProbID
       ON Edx.EdxTrackEvent(problem_id(255));

CREATE INDEX EdxTrackEventIdxVidID
       ON Edx.EdxTrackEvent(video_id(255));

CREATE INDEX EdxTrackEventIdxAnsID
       ON Edx.EdxTrackEvent(answer_id(255));

CREATE INDEX EdxTrackEventIdxSuccess
       ON Edx.EdxTrackEvent(success(15));

CREATE INDEX AnswerIdxAns
       ON Edx.Answer(answer(255));

CREATE INDEX AnswerIdxProbID
       ON Edx.Answer(problem_id(255));

CREATE INDEX AnswerIdxCourseID
       ON Edx.Answer(course_id(255));

CREATE INDEX AccountIdxUname
       ON EdxPrivate.Account(screen_name(255));

CREATE INDEX AccountIdxAnonUname
       ON EdxPrivate.Account(anon_screen_name(255));

CREATE INDEX AccountIdxZip
       ON EdxPrivate.Account(zipcode(10));

CREATE INDEX AccountIdxCoun
       ON EdxPrivate.Account(country(255));

CREATE INDEX AccountIdxGen
       ON EdxPrivate.Account(gender(6));

CREATE INDEX AccountIdxDOB
       ON EdxPrivate.Account(year_of_birth);

CREATE INDEX AccountIdxEdu
       ON EdxPrivate.Account(level_of_education(10));

CREATE INDEX AccountIdxCouID
       ON EdxPrivate.Account(course_id(255));
