'''
Created on Jun 13, 2017

Given a list and a number of list elements (chunk_size),
creates an iterator that will return a list of chunk_size
elements. Each call to next() returns the next segment
of the list. When the list is exhausted, StopIteration
is raised.

The class is usually imported. If run by itself, will
self-test.

Usage example: 

  feeder = ListChunkFeeder([1,2,3],2)
  feeder.next() ==> [1,2]
  feeder.next() ==> [3]
  feeder.next() ==> raises StopIteration.
  
or: 
  for chunk in ListChunkFeeder([1,2,3],2):
      print(chunk)

@author: paepcke
'''

class ListChunkFeeder(object):

    def __init__(self, long_list, chunk_size):

        self.long_list  = long_list
        self.chunk_size = chunk_size
        self.nxt_to_ret = 0
        self.lst_len    = len(long_list) 

    def __iter__(self):
        return self

    def next(self):
        
        cursor = self.nxt_to_ret
        if cursor >= self.lst_len:
            raise StopIteration
            
        if self.nxt_to_ret + self.chunk_size > self.lst_len:
            self.nxt_to_ret = self.lst_len
            return self.long_list[cursor:]

        # More than one chunk left to return:
        self.nxt_to_ret += self.chunk_size
        return (self.long_list[cursor:cursor + self.chunk_size])

    def chunc_size(self):
        return self.chunc_size

if __name__ == '__main__':
    
    # Unit tests:
    feeder =  ListChunkFeeder([],0)
    try:
        feeder.next()
        raise RuntimeError("Empty list should get immediate StopIteration")
    except StopIteration:
        pass
    
    feeder =  ListChunkFeeder([1],0)
    assert(feeder.next() == [])
    
    feeder =  ListChunkFeeder([1],1)
    assert(feeder.next() == [1])
    try:
        feeder.next()
        raise RuntimeError("Empty rest-list did not raise StopIteration")
    except StopIteration:
        pass
    
    feeder =  ListChunkFeeder([1,2],1)
    assert(feeder.next() == [1])
    assert(feeder.next() == [2])
    try:
        feeder.next()
        raise RuntimeError("Empty rest-list did not raise StopIteration")
    except StopIteration:
        pass
      
    feeder =  ListChunkFeeder([1,2],2)
    assert(feeder.next() == [1,2])
    try:
        feeder.next()
        raise RuntimeError("Empty rest-list did not raise StopIteration")
    except StopIteration:
        pass
    
    feeder =  ListChunkFeeder([1,2,3],2)
    assert(feeder.next() == [1,2])
    assert(feeder.next() == [3])
    try:
        feeder.next()
        raise RuntimeError("Empty rest-list did not raise StopIteration")
    except StopIteration:
        pass
    
    print('Passed all tests')  
