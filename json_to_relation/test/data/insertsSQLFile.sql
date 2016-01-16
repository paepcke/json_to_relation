# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

START TRANSACTION;
INSERT INTO EdxTrackEvent (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for,studentID,instructorID,courseID,seqID,gotoFrom,gotoDest,problemID,problemChoice,questionLocation,attempts,longAnswer,studentFile,canUploadFile,feedback,feedbackResponseSelected,transcriptID,transcriptCode,rubricSelection,rubricCategory,videoID,videoCode,videoCurrentTime,videoSpeed) VALUES 
    ('7a286e24_b578_4741_b6e0_c0e8596bd456','Mozilla/5.0 (Windows NT 6.1; WOW64; rv:22.0) Gecko/20100101 Firefox/22.0','browser','play_video','111.69.152.13','https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/f7325f1187a54b019105faa59524d73e/c82837a3f4044a3e8b72dd68ac28ee2a/','b2235e257dae729761f55efcfd583258','2013-08-04T06:53:03.033072+00:00','Annalise','0:00:00',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,'i4x-Medicine-HRP258-videoalpha-a35b3df40c2f44f0bdd0a238fb7e2bda','html5',924.913015,null);
INSERT INTO EdxTrackEvent (eventID,agent,event_source,event_type,ip,page,session,time,username,downtime_for) VALUES 
    ('1d4a63d7_3c44_4b74_9156_cb547060379e','ELB-HealthChecker/1.0','server','/heartbeat','127.0.0.1',null,null,'2013-08-04T06:53:03.953623+00:00','','0:00:00'),
    ('8a7e1e2e_d54e_45cf_a0ab_bdce47a6eb92','Mozilla/5.0 (Windows NT 6.1; WOW64; rv:22.0) Gecko/20100101 Firefox/22.0','server','/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/430b3a0f25924f0db96ee4d2987dcb98/check_for_score','71.205.233.245',null,null,'2013-08-04T06:53:05.770603+00:00','JoanneKMI','0:00:00'),
    ('a124d300_2df3_488b_8325_dccaea8fed24','Mozilla/5.0 (Windows NT 6.1; WOW64; rv:15.0) Gecko/20100101 Firefox/15.0.1','server','/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/42852761b6154efc9a68df085d0c148d/check_for_score','67.161.209.118',null,null,'2013-08-04T06:53:06.774159+00:00','Keri','0:00:00'),
    ('ca194323_a0fa_4454_a370_678b0eddc394','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML\, like Gecko) Chrome/28.0.1500.72 Safari/537.36','server','/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d/check_for_score','69.253.126.99',null,null,'2013-08-04T06:53:08.429580+00:00','KMotyka','0:00:00');
INSERT INTO Answer (answer_id,problem_id,answer) VALUES 
    ('ade4a9d9_8519_4756_983b_8b47381e3760','input_i4x-Medicine-HRP258-problem-75edd241d7c849ddb92bb7176fb27d0c_2_1','choice_0');
INSERT INTO EdxTrackEvent (eventID,agent,event_source,event_type,ip,page,session,time,username) VALUES 
    ('bd90c896_d0f3_42f6_ba9a_c0f1de59b3c7','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML\, like Gecko) Chrome/28.0.1500.72 Safari/537.36','server','/courses/Education/EDUC115N/How_to_Learn_Math/modx/i4x://Education/EDUC115N/combinedopenended/4abb8b47b03d4e3b8c8189b3487f4e8d/check_for_score','69.253.126.99',null,null,'2013-08-04T06:53:30.427990+00:00','KMotyka');
COMMIT Transaction;
