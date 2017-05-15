# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# We need the framework that perfoms standard code for the main-program
import test_phase

# We usualy need specific phases
# NOTE: `frontend` is sufficent in most case (it is often too much)
import frontend

import metrics_base
import mclasses_metrics
import semantize

import codesmells_metrics

# The body of the specific work.
# The main entry point is provided by `test_phase`,
# This function is then automatically (unless errors where found).
redef fun do_work(mainmodule, given_mmodules, modelbuilder)
do
	var model = modelbuilder.model
	var mclasses = mainmodule.flatten_mclass_hierarchy


	#New array of classedef
	var aclassdefs = new Array [AClassdef]

	#New array of classe
	var mclasse = new Array [MClass]

	# search all class and classdef and put they in the array
	for m in mclasses do
		mclasse.add(m)
	end

	for nmodule in modelbuilder.nmodules do
		for nclassdef in nmodule.n_classdefs do
			aclassdefs.add(nclassdef)
		end
	end


	for aclassdef in aclassdefs do
		# Execute antipattern detection
		var m = aclassdef.mclassdef
		if m != null then
			print "Class : {m.name}"
			m.mclassantipatterns.collect(aclassdef)
			m.mclasscodesmell.collect(aclassdef)
			m.mclassantipatterns.printAll
			m.mclasscodesmell.printAll
		end		
	end
end
