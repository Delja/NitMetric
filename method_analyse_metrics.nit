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

module method_analyse_metrics

# We usualy need specific phases
# NOTE: `frontend` is sufficent in most case (it is often too much)
import frontend

import metrics_base
import mclasses_metrics
import semantize

fun callvisiteMethodAnalyse(aclasse : AClassdef) : Array[MethodAnalyse] do
	var visitors = new Array[MethodAnalyse]
	for n_prop in aclasse.n_propdefs do
		#Check if the property is a method definition
		if n_prop isa AMethPropdef then 
			if n_prop.n_methid isa AIdMethid then
				#Call visitor to analyse the method
				var visitor = new MethodAnalyse(n_prop)
				visitor.enter_visit(n_prop)
				visitors.add(visitor)
			end
		end
	end
	return visitors
end

public class MethodAnalyse
	super Visitor
	var nclassdef: AMethPropdef

	var total_call = new Counter[ASendExpr]
	var lineDetail = new Counter[ASendExpr]
	var total_call_self = new Counter[ASendExpr]



	redef fun visit(n)
	do
		n.visit_all(self)

		if n isa ASendExpr then
			if n.raw_arguments.length != 0 then
				lineDetail.inc(n)
			end

			var callsite = n.callsite
			if callsite != null then
				self.total_call.inc(n)
				if callsite.recv_is_self == true then
					self.total_call_self.inc(n)
				end
			end
		end
	end
end