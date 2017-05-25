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

# Detect the code smells and antipatterns in the code.

module codesmells_metrics

import frontend

import metrics_base
import mclasses_metrics
import semantize

import method_analyse_metrics
import mclassdef_collect


redef class ToolContext
	var codesmells_metrics_phase: Phase = new CodeSmellsMetricsPhase(self, null)
end

private class CodeSmellsMetricsPhase
	super Phase

	redef fun process_mainmodule(mainmodule, given_mmodules)
	do
		print "--- Code Smells Metrics ---"
		var mclazzs = mainmodule.flatten_mclass_hierarchy
		var mclassdefs = new Array [MClassDef]
 		for mclass in mclazzs do
	 		for cd in mclass.mclassdefs do
	 			mclassdefs.add(cd)
	 		end
 		end
 		var collect = new Counter[MClassDef]
 		for m in mclassdefs do
			# Execute antipattern detection
			#m.mclassantipatterns.collect(m , toolcontext.modelbuilder)
			collect.add_all(m.mclasscodesmell.collect(m , toolcontext.modelbuilder))
		end

		#Return top 10 list and print
		var top_mclassdefs = new Array [MClassDef]
		top_mclassdefs = collect.get_element(10)

		for mclassdef in top_mclassdefs do
			#mclassdef.mclasscodesmell.print_all(mclassdef)
		end
		toolcontext.modelbuilder.model.private_view.getAverageLineNumber(toolcontext.modelbuilder)
	end
end

class BadConceptions
	#Code smell list
	var bad_conception_element = new Array[BadConception]
	# Print all element conception
	fun print_all(clazz : MClassDef) do
		print "-------------------"
		print "Class: {clazz.name}"
		for cd in bad_conception_element do
			if cd.result == true then
				cd.print_result
			end
		end
	end

	#Collection
	fun collect(clazz : MClassDef, modelbuilder : ModelBuilder) : Counter[MClassDef] do
		var n_classdef = modelbuilder.mclassdef2node(clazz)
		var counter = new Counter[MClassDef]
		if n_classdef != null then
			for cd in bad_conception_element do
				cd.collect(n_classdef, modelbuilder.model.private_view)
			end
		end
		for cd in bad_conception_element do
			if cd.result == true then
				counter.inc(clazz)
			end
		end
		return counter
	end
end

class Antipatterns
	super BadConceptions
	init do
		#bad_conception_element.add(new GOC)
	end
end

class CodeSmells
	super BadConceptions
	init do
		bad_conception_element.add(new LargeClass)
		bad_conception_element.add(new LongParameterList)
		bad_conception_element.add(new FeatureEnvy)
		bad_conception_element.add(new LongMethod)
	end
end

class BadConception
	#Bool Result
	var result = false

	#Name
	fun name: String do
		return ""
	end

	#Description
	fun desc: String do
		return ""
	end

	#Collection method
	fun collect(n_classdef : AClassdef, model_view : ModelView)do end

	#Show results in console
	fun print_result do
		print "{desc}:  {result}"
	end
end


class Antipattern
	super BadConception
end


class CodeSmell
	super BadConception
end


class LargeClass
	super CodeSmell

	redef fun name do
		return "LARGC"
	end
	redef fun desc do
		return "Large class"
	end

	redef fun collect(n_classdef, model_view) do
		#get class definition
		var mclassdef = n_classdef.mclassdef
		var numberAttribut = mclassdef.collect_intro_mattributes.length
		#get the number of methods and subtract the get and set of attibutes (numberAtribut*2)
		var numberMethode = mclassdef.collect_intro_mmethods.length - (numberAttribut*2)
		if numberMethode.to_f > model_view.getAverageMethodNumber or numberAttribut.to_f > model_view.getAverageAttributNumber then result = true
	end
end

class LongParameterList
	super CodeSmell

	var bad_methods = new Array[MMethodDef]

	redef fun name do
		return "LONGPL"
	end
	redef fun desc do
		return "Long parameter list"
	end

	redef fun collect(n_classdef, model_view) do
		#get class definition
		var mclassdef = n_classdef.mclassdef
		for meth in mclassdef.mpropdefs do
			#check if the property is a method definition
			if meth isa MMethodDef then
				#Check if method has a signature
				if meth.msignature != null then
					if meth.msignature.mparameters.length >= 4 then
						bad_methods.add(meth)
						result = true
					end
				end
			end
		end
	end


	redef fun print_result do
		print "{desc} :  {result}"
		if bad_methods.length >= 1 then
			print "Affected method:"
			for method in bad_methods do
				print "{method.name}"
			end
		end
	end
end


class FeatureEnvy
	super CodeSmell

	var bad_methods = new Array[AIdMethid]

	redef fun name do
		return "FEM"
	end
	redef fun desc do
		return "Feature envy"
	end

	redef fun collect(n_classdef, model_view) do
		#Call the visit class method
		var visits = call_analyze_methods(n_classdef)
		for visit in visits do
			if (visit.total_call_self.length - visit.total_call_self.length) > visit.total_call_self.length then
				result = true
				bad_methods.add(visit.nclassdef.n_methid.as(AIdMethid))
			end
		end

	end


	redef fun print_result do
		print "{desc} :  {result}"
		if bad_methods.length >= 1 then
			print "Affected method:"
			for method in bad_methods do
				print "{method.n_id.text}"
			end
		end
	end
end

class LongMethod
	super CodeSmell

	var bad_methods = new Array[AIdMethid]

	redef fun name do
		return "LONGMETH"
	end
	redef fun desc do
		return "Long method"
	end

	redef fun collect(n_classdef, model_view) do
		var visits = call_analyze_methods(n_classdef)
		for visit in visits do
			if visit.lineDetail.length > 30 then
				result = true
				bad_methods.add(visit.nclassdef.n_methid.as(AIdMethid))
			end
		end
	end


	redef fun print_result do
		print "{desc}:  {result}"
		if bad_methods.length >= 1 then
			print "Affected method:"
			for method in bad_methods do
				print "{method.n_id.text}"
			end
		end
	end
end



redef class MClassDef
	var mclassantipatterns = new Antipatterns
	var mclasscodesmell = new CodeSmells
end


redef class ModelView
	
	fun getAverageParameter : Float do
		var counter = new Counter[MMethodDef]
		for mclassdef in mclassdefs do
			for method in mclassdef.mpropdefs do
			#check if the property is a method definition
				if method isa MMethodDef then
					#Check if method has a signature
					if method.msignature != null then
						if method.msignature.mparameters.length != 0 then
							counter[method] = method.msignature.mparameters.length
						end
					end
				end
			end
		end
		return counter.avg + counter.std_dev
	end

	fun getAverageAttributNumber : Float do
		var counter = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var numberAttribut = mclassdef.collect_intro_mattributes.length
			if numberAttribut != 0 then counter[mclassdef] = numberAttribut
		end
		return counter.avg + counter.std_dev
	end

	fun getAverageMethodNumber : Float do
		var counter = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var numberMethode = mclassdef.collect_intro_mmethods.length
			if numberMethode != 0 then counter[mclassdef] = numberMethode
		end
		return counter.avg + counter.std_dev
	end

	fun getAverageLineNumber(modelbuilder : ModelBuilder) : Int do
		var methods_analyse_metrics = new Counter[MClassDef]
		var result = 0
		for mclassdef in mclassdefs do
			var n_classdef = modelbuilder.mclassdef2node(mclassdef)
			if n_classdef != null then
				for method_analyse in call_analyze_methods(n_classdef) do
					result += method_analyse.lineDetail.length
				end
				if mclassdef.collect_intro_mmethods.length != 0 then
					methods_analyse_metrics[mclassdef] = (result/mclassdef.collect_intro_mmethods.length).to_i
				end
			end
		end
		print "{methods_analyse_metrics.avg + methods_analyse_metrics.std_dev}"
		return result
	end
end


redef class Counter
	#Return the n first elements
	fun get_element(number : Int) : Array[E]do
		var return_values = new Array[E]
		var list = self.sort
		var min = number
		if list.length <= number*2 then min = list.length
		for i in [0..min[ do
			var t = list[list.length-i-1]
			return_values.add(t)
		end
		return return_values
	end
end