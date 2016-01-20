# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

CREATE INDEX EdxTrackEventIdxTime
       ON Edx.EdxTrackEvent(time);

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
