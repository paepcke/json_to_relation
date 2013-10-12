'''
Created on Oct 11, 2013

@author: paepcke
'''
import json
import unittest


class Test(unittest.TestCase):

    def get_course_id(self, event):
        '''
        Given a 'pythonized' JSON tracking event object, find
        the course URL, and extract the course name from it.
        A number of different events occur, which do not contain
        course IDs: server heartbeats, account creation, dashboard
        accesses. Among them are logins, which look like this:
        
        {"username": "", 
         "host": "class.stanford.edu", 
         "event_source": "server", 
         "event_type": "/accounts/login", 
         "time": "2013-06-14T00:31:57.661338", 
         "ip": "98.230.189.66", 
         "event": "{
                    \"POST\": {}, 
                    \"GET\": {
                         \"next\": [\"/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/80160e.../\"]}}", 
         "agent": "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101
         Firefox/21.0", 
         "page": null}
        
        Notice the 'event' key's value being a *string* containing JSON, rather than 
        a nested JSON object. This requires special attention. Buried inside
        that string is the 'next' tag, whose value is an array with a long (here
        partially elided) hex number. This is where the course number is
        extracted.
        
        @param event: JSON record of an edx tracking event as internalized dict
        @type event: Dict<String,Dict<<any>>
        @return: two-tuple: fulle name of course in which event occurred, and descriptive name.
                 None if course ID could not be obtained.
        @rtype: {(String,String) | None} 
        '''
        course_id = None
        if event['event_source'] == 'server':
            # get course_id from event type
            if event['event_type'] == u'/accounts/login':
                post = json.loads(event['event'])
                fullCourseName = post['GET']['next'][0]
            else:
                fullCourseName = event['event_type']
        else:
            fullCourseName = event['page']
        if fullCourseName:
            courseNameFrags = fullCourseName.split('/')
            if 'courses' in courseNameFrags:
                i = courseNameFrags.index('courses')
                course_id = "/".join(map(str, courseNameFrags[i+1:i+4]))
        if course_id is None:
            fullCourseName = None
        return (fullCourseName, course_id)



    def testCourseIDExtraction(self):
        # login events:
        event = '{"username": "", "host": "class.stanford.edu", "event_source": "server", "event_type": "/accounts/login", "time": "2013-06-18T10:25:01.395788+00:00", "ip": "96.244.230.65", "event": "{\\"POST\\": {}, \\"GET\\": {\\"next\\": [\\"/courses/Medicine/HRP258/Statistics_in_Medicine/courseware\\"]}}", "agent": "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0", "page": null}'
        eventDict = json.loads(event)
        (fullName, course_id) = self.get_course_id(eventDict)
        self.assertEqual('/courses/Medicine/HRP258/Statistics_in_Medicine/courseware', fullName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', course_id)
        
        # video seek:
        event = '{"username": "smith", "host": "class.stanford.edu", "session": "c2c122e3d3e8e0a107588f01e7907119", "event_source": "browser", "event_type": "seek_video", "time": "2013-06-18T03:12:54.287564+00:00", "ip": "69.203.10.97", "event": "{\\"id\\":\\"i4x-Medicine-HRP258-videoalpha-655cbd5cd8994b009f8f4e3717a44cf7\\",\\"code\\":\\"html5\\",\\"old_time\\":472,\\"new_time\\":487,\\"type\\":\\"slide_seek\\"}", "agent": "Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36", "page": "https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/495757ee7b25401599b1ef0495b068e4/8d1c1b48b7cf42ef851bdf42e12a50c7/"}'
        eventDict = json.loads(event)
        (fullName, course_id) = self.get_course_id(eventDict)
        self.assertEqual('https://class.stanford.edu/courses/Medicine/HRP258/Statistics_in_Medicine/courseware/495757ee7b25401599b1ef0495b068e4/8d1c1b48b7cf42ef851bdf42e12a50c7/',
                         fullName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', course_id)

        # save_problem_check 
        event = '{"username": "doe", "host": "class.stanford.edu", "event_source": "server", "event_type": "save_problem_check", "time": "2013-06-18T03:12:47.641200+00:00", "ip": "78.45.97.170", "event": {"success": "correct", "correct_map": {"i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_2_1": {"hint": "", "hintmode": null, "correctness": "correct", "msg": "", "npoints": null, "queuestate": null}, "i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_3_1": {"hint": "", "hintmode": null, "correctness": "correct", "msg": "", "npoints": null, "queuestate": null}}, "attempts": 4, "answers": {"i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_2_1": "choice_0", "i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_3_1": "choice_4"}, "state": {"student_answers": {"i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_2_1": "choice_0", "i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_3_1": "choice_4"}, "seed": 1, "done": true, "correct_map": {"i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_2_1": {"hint": "", "hintmode": null, "correctness": "correct", "msg": "", "npoints": null, "queuestate": null}, "i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_3_1": {"hint": "", "hintmode": null, "correctness": "correct", "msg": "", "npoints": null, "queuestate": null}}, "input_state": {"i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_2_1": {}, "i4x-Medicine-HRP258-problem-494a95733c25404e9d607ac966d5ba0a_3_1": {}}}, "problem_id": "i4x://Medicine/HRP258/problem/494a95733c25404e9d607ac966d5ba0a"}, "agent": "Mozilla/5.0 (Windows NT 5.1; rv:17.0) Gecko/20100101 Firefox/17.0", "page": "x_module"}'
        eventDict = json.loads(event) 
        (fullName, course_id) = self.get_course_id(eventDict)
        self.assertIsNone(fullName)
        self.assertIsNone(course_id)

        # problem_check
        event = '{"username": "jane", "host": "class.stanford.edu", "event_source": "server", "event_type": "/courses/Medicine/HRP258/Statistics_in_Medicine/modx/i4x://Medicine/HRP258/problem/67a883f792d8415b8e492082d0d361ff/problem_check", "time": "2013-06-17T22:56:31.698182+00:00", "ip": "67.2.70.170", "event": "{\\"POST\\": {\\"input_i4x-Medicine-HRP258-problem-67a883f792d8415b8e492082d0d361ff_2_1\\": [\\"choice_3\\"]}, \\"GET\\": {}}", "agent": "Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20100101 Firefox/21.0", "page": null}'
        eventDict = json.loads(event) 
        (fullName, course_id) = self.get_course_id(eventDict)
        self.assertEqual('/courses/Medicine/HRP258/Statistics_in_Medicine/modx/i4x://Medicine/HRP258/problem/67a883f792d8415b8e492082d0d361ff/problem_check',
                         fullName)
        self.assertEqual('Medicine/HRP258/Statistics_in_Medicine', course_id)
        
        # problem_reset
        event = '{"username": "zdodds", "host": "preview.class.stanford.edu", "event_source": "server", "event_type": "/courses/HMC/MyCS/Middle-years_Computer_Science/modx/i4x://HMC/MyCS/problem/d4c4833f051141b38cf932d6358ab27b/problem_reset", "time": "2013-06-18T17:57:14.853776+00:00", "ip": "134.173.248.2", "event": "{\\"POST\\": {\\"id\\": [\\"i4x://HMC/MyCS/problem/d4c4833f051141b38cf932d6358ab27b\\"]}, \\"GET\\": {}}", "agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36", "page": null}'        
        eventDict = json.loads(event) 
        (fullName, course_id) = self.get_course_id(eventDict)
        self.assertEqual('/courses/HMC/MyCS/Middle-years_Computer_Science/modx/i4x://HMC/MyCS/problem/d4c4833f051141b38cf932d6358ab27b/problem_reset',
                         fullName)
        self.assertEqual('HMC/MyCS/Middle-years_Computer_Science', course_id)


        print fullName
        print course_id
        
        



if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()