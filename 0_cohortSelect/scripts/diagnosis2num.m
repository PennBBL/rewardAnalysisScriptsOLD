function out = diagnosis2num(dx)

% function to numericise diagnoses

switch dx
    case 'noDiagnosis'
        out = 0;
    case 'Schizophrenia'
        out = 1;
    case 'Schizoaffective'
        out = 1;
    case 'Schizophreniform'
        out = 1;
    case 'psychoticDisorderNOS'
        out = 1;
    case 'bipolarDisorderNOS'
        out = 2;
    case 'bipolarDisorderTypeI'
        out = 2;
    case 'bipolarDisorderTypeII'
        out = 2;
    case 'bipoloarDisorderNOS' % sic
        out = 2;
    case 'depressiveDisorderNOS'
        out = 2;
    case 'majorDepressiveDisorder'
        out = 2;
    case 'clinicalRisk'
        out = 1;
    otherwise
        out = -1;

end