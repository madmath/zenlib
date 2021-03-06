#cython: embedsignature=True

"""
This module provides functions that randomize existing networks.

Since all functions involve calls to the system random number generator, all functions accept the optional arguments

	- seed [=None]: sets the seed to be set in the random generator. If not specified, then no change is made to the
		random seed.
"""

from graph cimport Graph
from digraph cimport DiGraph
from exceptions import *

from random import choice, randint
from random import shuffle as rnd_shuffle

from cpython cimport bool
from libc.stdlib cimport srand, rand, RAND_MAX

cdef extern from "math.h" nogil:
	double floor( double arg )

__all__ = ['choose_node','choose_node_','choose_edge','choose_edge_','shuffle']

def choose_node(G,**kwargs):
	"""
	Choose a random node object from the graph G.  
	
	From a performance perspective, the performance of this method will degrade as the
	ratio of num_nodes/max_node_idx approaches zero.  This is because the random node is
	selected by selecting a random index into the node array.  The more holes that exist
	in the node array, the more random tries will be required to find a valid node.
	"""
	seed = kwargs.pop('seed',None)
	
	if len(kwargs) > 0:
		raise ZenException, 'Unknown arguments: %s' % ', '.join(kwargs.keys())
		
	if seed is None:
		seed = -1
	
	if type(G) == Graph:
		return G.node_object(ug_choose_node_(<Graph>G,seed))
	elif type(G) == DiGraph:
		return G.node_object(dg_choose_node_(<DiGraph>G,seed))
	else:
		raise ZenException, 'Graph of type %s is not supported' % str(type(G))
	
def choose_node_(G,**kwargs):
	"""
	Choose a random node index from the graph G.  
	
	From a performance perspective, the performance of this method will degrade as the
	ratio of num_nodes/max_node_idx approaches zero.  This is because the random node is
	selected by selecting a random index into the node array.  The more holes that exist
	in the node array, the more random tries will be required to find a valid node.
	"""
	seed = kwargs.pop('seed',None)
	
	if len(kwargs) > 0:
		raise ZenException, 'Unknown arguments: %s' % ', '.join(kwargs.keys())
		
	if seed is None:
		seed = -1
		
	if type(G) == Graph:
		return ug_choose_node_(<Graph>G,seed)
	elif type(G) == DiGraph:
		return dg_choose_node_(<DiGraph>G,seed)
	else:
		raise ZenException, 'Graph of type %s is not supported' % str(type(G))
	
cpdef int ug_choose_node_(Graph G,int seed):

	if seed >= 0:
		srand(seed)

	cdef float num_idx = G.next_node_idx
	cdef int nidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
	while G.node_info[nidx].exists == False:
		nidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
		
	return nidx
	
cpdef int dg_choose_node_(DiGraph G,int seed):

	if seed >= 0:
		srand(seed)

	cdef float num_idx = G.next_node_idx
	cdef int nidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
	while G.node_info[nidx].exists == False:
		nidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
	
	return nidx

def choose_edge(G,**kwargs):
	"""
	Choose a random edge from the graph G.  
	
	From a performance perspective, the performance of this method will degrade as the
	ratio of num_edges/max_edge_idx approaches zero.  This is because the random edge is
	selected by selecting a random index into the edge array.  The more holes that exist
	in the edge array, the more random tries will be required to find a valid edge.
	"""
	seed = kwargs.pop('seed',None)
	
	if len(kwargs) > 0:
		raise ZenException, 'Unknown arguments: %s' % ', '.join(kwargs.keys())
		
	if seed is None:
		seed = -1
	
	if type(G) == Graph:
		return G.endpoints(ug_choose_edge_(<Graph>G,seed))
	elif type(G) == DiGraph:
		return G.endpoints(dg_choose_edge_(<DiGraph>G,seed))
	else:
		raise ZenException, 'Graph of type %s is not supported' % str(type(G))

def choose_edge_(G,**kwargs):
	"""
	Choose a random edge index from the graph G.  
	
	From a performance perspective, the performance of this method will degrade as the
	ratio of num_edges/max_edge_idx approaches zero.  This is because the random edge is
	selected by selecting a random index into the edge array.  The more holes that exist
	in the edge array, the more random tries will be required to find a valid edge.
	"""
	seed = kwargs.pop('seed',None)
	
	if len(kwargs) > 0:
		raise ZenException, 'Unknown arguments: %s' % ', '.join(kwargs.keys())
		
	if seed is None:
		seed = -1
	
	if type(G) == Graph:
		return ug_choose_edge_(<Graph>G,seed)
	elif type(G) == DiGraph:
		return dg_choose_edge_(<DiGraph>G,seed)
	else:
		raise ZenException, 'Graph of type %s is not supported' % str(type(G))
		
cpdef int ug_choose_edge_(Graph G,int seed):

	if seed >= 0:
		srand(seed)
	
	cdef float num_idx = G.next_edge_idx
	cdef int eidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
	while G.edge_info[eidx].exists == False:
		eidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
		
	return eidx

cpdef int dg_choose_edge_(DiGraph G,int seed):

	if seed >= 0:
		srand(seed)
	
	cdef float num_idx = G.next_edge_idx
	cdef int eidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
	while G.edge_info[eidx].exists == False:
		eidx = <int>floor(num_idx * (<float>rand() / RAND_MAX))
		
	return eidx
	
def shuffle(G,**kwargs):
	"""
	Shuffle the edges in this network.  Keyword arguments can include:
	
	  - keep_degree True/[False] indicates whether the degree of each node in the original network
								 should be retained in the shuffled version
	  - self_loops True/[False]  indicates whether self-loops should be permitted in the shuffled version
								 of the network
	  - seed [=None]: specify the seed that is used by the random number generator.
	"""
	
	# parse parameters
	keep_degree = kwargs.pop('keep_degree',False)
	self_loops = kwargs.pop('self_loops',False)
	seed = kwargs.pop('seed',None)
	
	if len(kwargs) > 0:
		raise ZenException, 'Unknown arguments: %s' % ', '.join(kwargs.keys())
	
	if seed is None:
		seed = -1
		
	# call the appropriate function
	if type(G) == Graph:
		return ug_shuffle(<Graph>G,keep_degree,self_loops,seed)
	elif type(G) == DiGraph:
		return dg_shuffle(<DiGraph>G,keep_degree,self_loops,seed)
	else:
		raise InvalidGraphTypeException, 'Unknown graph type %s' % str(type(G))
	
cdef Graph ug_shuffle(Graph G,bool keep_degree,bool self_loops,int seed):
	
	if seed >= 0:
		srand(seed)
	
	dG = Graph()
	
	if not keep_degree:
		# add all nodes
		for n,data in G.nodes_iter(True):
			dG.add_node(n,data)
		
		# shuffle edges
		all_nodes = dG.nodes()
		for e,data,weight in G.edges_iter_(-1,True,True):
			# pick two random nodes to connect
			x = choice(all_nodes)
			y = choice(all_nodes)
			while (not self_loops and x == y) or dG.has_edge(x,y):
				x = choice(all_nodes)
				y = choice(all_nodes)

			e = dG.add_edge(x,y,data)
			dG.set_weight_(e,weight)
	else:
		# add all nodes
		for n,data in G.nodes_iter(True):
			dG.add_node(n,data)
		
		# add all edges
		for x,y,data,weight in G.edges_iter(None,True,True):
			e = dG.add_edge(x,y,data)
			dG.set_weight_(e,weight)
		
		#####	
		# swap edge endpoints
			
		# swap every edge two times
		num_iters = 3
		for x in range(num_iters):
			edges = [(x,y,data,weight) for x,y,data,weight in dG.edges_iter(None,True,True)]
			rnd_shuffle(edges)
			
			while len(edges) >= 2:
				e1 = edges.pop()
				e2 = edges.pop()
				idx = randint(0,1)
				
				if randint(0,1) == 0:
					u1 = e2[0]
					v1 = e1[1]
					u2 = e1[0]
					v2 = e2[1]
				else:
					u1 = e1[0]
					v1 = e2[1]
					u2 = e2[0]
					v2 = e1[1]
					
				if not dG.has_edge(u1,v1) and not dG.has_edge(u2,v2):
					dG.rm_edge(e1[0],e1[1])
					dG.rm_edge(e2[0],e2[1])
					e = dG.add_edge(u1,v1,e1[2])
					dG.set_weight_(e,e1[3])
					e = dG.add_edge(u2,v2,e2[2])
					dG.set_weight_(e,e2[3])
					
	return dG
	
cdef DiGraph dg_shuffle(DiGraph G,bool keep_degree,bool self_loops,int seed):

	if seed >= 0:
		srand(seed)

	dG = DiGraph()

	if not keep_degree:
		# add all nodes
		for n,data in G.nodes_iter(True):
			dG.add_node(n,data)

		# shuffle edges
		all_nodes = dG.nodes()
		for e,data,weight in G.edges_iter_(-1,True,True):
			# pick two random nodes to connect
			x = choice(all_nodes)
			y = choice(all_nodes)
			while (not self_loops and x == y) or dG.has_edge(x,y):
				x = choice(all_nodes)
				y = choice(all_nodes)

			e = dG.add_edge(x,y,data)
			dG.set_weight_(e,weight)
	else:
		# add all nodes
		for n,data in G.nodes_iter(True):
			dG.add_node(n,data)

		# add all edges
		for x,y,data,weight in G.edges_iter(None,True,True):
			e = dG.add_edge(x,y,data)
			dG.set_weight_(e,weight)

		#####	
		# swap edge endpoints

		# swap every edge two times
		num_iters = 3
		for x in range(num_iters):
			edges = [(x,y,data,weight) for x,y,data,weight in dG.edges_iter(None,True,True)]
			rnd_shuffle(edges)
			
			while len(edges) >= 2:
				e1 = edges.pop()
				e2 = edges.pop()
				idx = randint(0,1)

				if randint(0,1) == 0:
					u1 = e2[0]
					v1 = e1[1]
					u2 = e1[0]
					v2 = e2[1]
				else:
					u1 = e1[0]
					v1 = e2[1]
					u2 = e2[0]
					v2 = e1[1]

				if not dG.has_edge(u1,v1) and not dG.has_edge(u2,v2):
					dG.rm_edge(e1[0],e1[1])
					dG.rm_edge(e2[0],e2[1])
					e = dG.add_edge(u1,v1,e1[2])
					dG.set_weight_(e,e1[3])
					e = dG.add_edge(u2,v2,e2[2])
					dG.set_weight_(e,e2[3])

	return dG