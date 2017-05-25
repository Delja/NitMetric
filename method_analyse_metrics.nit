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

# This module call visitor for get number of line, total attributs call and total of self attributes call

module method_analyse_metrics

# We usualy need specific phases
# NOTE: `frontend` is sufficent in most case (it is often too much)
import frontend

import metrics_base
import mclasses_metrics
import semantize


fun call_analyze_methods(aclasse : AClassdef) : Array[MethodAnalyseMetrics] do
	var visitors = new Array[MethodAnalyseMetrics]
	for n_prop in aclasse.n_propdefs do
		#Check if the property is a method definition
		if n_prop isa AMethPropdef then
			if n_prop.n_methid isa AIdMethid then
				#Call visitor to analyse the method
				var visitor = new MethodAnalyseMetrics(n_prop)
				visitor.enter_visit(n_prop)
				visitors.add(visitor)
			end
		end
	end
	return visitors
end

public class MethodAnalyseMetrics
	super Visitor
	var nclassdef: AMethPropdef
	var total_call = new Counter[ASendExpr]
	var lineDetail = new Counter[nullable Int]
	var total_call_self = new Counter[ASendExpr]

	redef fun visit(n)
	do
		n.visit_all(self)

		if n isa ASendExpr then
			if n.first_location != null then
				lineDetail.inc(n.first_location.line_start)
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