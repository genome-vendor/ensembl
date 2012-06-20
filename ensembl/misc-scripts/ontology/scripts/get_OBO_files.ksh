#!/bin/ksh

# GO    - Gene Ontology
wget -O GO.obo "http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology.1_2.obo"

# SO    - Sequence Ontology
wget -O SO.obo "http://berkeleybop.org/ontologies/obo-all/sequence/sequence.obo"

# EFO   - Experimental Factor Ontology
wget -O EFO.obo "http://efo.svn.sourceforge.net/svnroot/efo/trunk/src/efoinobo/efo.obo"

exit

# ----------------------------------------------------------------------
# Ontologies used in the Gramene project

# PO    - Plant Ontology
wget -O PO.obo "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/OBO_format/po_anatomy.obo?view=co"

# GRO   - Plant Growth Stage Ontology
wget -O GRO.obo "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/collaborators_ontology/gramene/temporal_gramene.obo?view=co"

# TO    - Plant Traits Ontology
wget -O TO.obo "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/collaborators_ontology/gramene/traits/trait.obo?view=co"

# GR_tax    - Gramene Taxonomy Ontology
wget -O GR_tax.obo "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/collaborators_ontology/gramene/taxonomy/GR_tax-ontology.obo?view=co"

# EO    - Plant Envionment Ontology
wget -O EO.obo "http://obo.cvs.sourceforge.net/viewvc/obo/obo/ontology/phenotype/environment/environment_ontology.obo"

# $Id: get_OBO_files.ksh,v 1.6 2011/02/23 10:12:28 mk8 Exp $
