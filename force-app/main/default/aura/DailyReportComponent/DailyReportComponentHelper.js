({
    getColumns: function(project){
        if(project.AssignOnProject__r.length > 1){
            return Object.keys(project.AssignOnProject__r[0]);
        }else{
            return [];
        }
    },
})