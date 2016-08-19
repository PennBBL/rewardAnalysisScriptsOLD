function [h] = qtask_plotKm(kmsc,titleStr)
% plot a single subject's kaplan-meier survival function
% (return the handle to the data series object)

h = stairs(kmsc(:,1),kmsc(:,2),'LineWidth',2);
set(gca,'YLim',[0, 1.1],'XLim',[0, max(kmsc(:,1))+0.1],'Box','off','FontSize',16);
xlabel('Time (s)');
ylabel('Survival rate');

% add a title if one was supplied
if nargin>1
    title(titleStr,'Interpreter','none');
end


