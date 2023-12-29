## install library RODBC 

library(RODBC)
db = odbcConnect("mysql_server_64", uid="root", pwd="root")
sqlQuery(db, "USE ma_charity_full")

# abstracting the dataset(ma_charity_full) SQL
q1= "SELECT * FROM ma_charity_full.assignment2"
data = sqlQuery(db,q1)

#abstracting the acts table from database
q2= "SELECT * FROM ma_charity_full.acts"
acts = sqlQuery(db, q2)
odbcClose(db)


#dividing the datasets into  calibration and prediction
data$amount = ifelse(test = data$donation < 1 , yes = 0, no=data$amount )

calibration_data = data[which(data$calibration == 1),]
prediction_data = data[which(data$calibration == 0),]


#Using the library sqldf for querrying database in SQL
library(sqldf)

donation= sqldf("SELECT contact_id,act_type_id,
                       MIN(act_date)  AS 'fbuyed',
                       MAX(act_date)  AS 'recency',
                       COUNT(*) AS 'frequency',
                       AVG(amount) AS 'avg_amount',
                       MAX(amount) AS 'max_amount'
                       FROM acts
                       WHERE act_type_id = 'DO'
                       GROUP BY 1")
donation$recency = as.Date(donation$recency, origin = "1970-01-01")
donation$fbuyed =as.Date(donation$fbuyed, origin = "1970-01-01")
donation$recency= as.numeric(difftime(time1 = "2017-05-24",
                                            time2 = donation$recency,
                                            units = "days"))
donation$recency = round(donation$recency)
donation$fbuyed= as.numeric(difftime(time1 = "2017-05-24",
                                       time2 = donation$fbuyed,
                                       units = "days"))
donation$fbuyed= round(donation$fbuyed)

# Combine donors of different caampaigns 
in_sample = merge(calibration_data,donation, all.x = TRUE)
in_sample$amount[is.na(calibration_data$amount)] = 0
View(in_sample[is.na(in_sample$act_type_id),])
## get summary of in_sample
summary(in_sample)
in_sample = in_sample [which(in_sample$act_type_id == "DO"),]

#use of nnet library for multinom function
library(nnet)

# create a Probability Model
prob.model = multinom(formula = donation ~ log(frequency) +log(recency) + recency +frequency+ fbuyed, data=in_sample)

coeff = summary(prob.model)$coefficients
stder = summary(prob.model)$standard.error
print(coeff)
print(stder)
z = coeff/stder
print(z)


# create a Amount Model
Pgen_donors = which(in_sample$donation == 1)

Pgen_donors=(in_sample[Pgen_donors, ])
summary(Pgen_donors)

amount.model = lm(formula = log(amount) ~ log(avg_amount) + log(max_amount) + log(frequency)+ log(fbuyed), data = Pgen_donors)
summary(amount.model)

plot(x = log(Pgen_donors$amount), y = amount.model$fitted.values)

#here we are making  the out_sample for predictions
out_sample = merge(prediction_data,donation, all.x = TRUE)

#Reduce columns
drops <- c("calibration","donation","amount","act_date")
out_sample=out_sample[ , !(names(out_sample) %in% drops)]

summary(out_sample)
out_sample = out_sample [which(out_sample$act_type_id == "DO"),]

#-------Predict the target variables based on previous data
out_sample$probs    = predict(object = prob.model, newdata = out_sample, type = "probs")
out_sample$revenue = exp(predict(object = amount.model, newdata = out_sample))
out_sample$predi_score   = out_sample$probs * out_sample$revenue
#View(out_sample)
summary(out_sample$probs)
summary(out_sample$revenue)
summary(out_sample$predi_score)
hist(out_sample$predi_score)

#As given in document, we consider if revenue predicted is more than 2  then solicit = 1 or 0 in other case

out_sample$solicit = ifelse (out_sample$predi_score >= 2 , 1 , 0)
drops2<-c("fbuyed","frequency","avg_amount","recency","max_amount","probs","act_type_id","revenue","predi_score")
final<- out_sample[ , !(names(out_sample) %in% drops2)]
final = merge(prediction_data,final, all.x = TRUE)
final$solicit[is.na(final$solicit)] = 0
final=final[ , !(names(final) %in% drops)]
## create a text file with two columns as customer id and solicitation number(0 or 1)
write.table(final, file = "PankajMA_2.txt",sep = "\t",row.names = FALSE, col.names = FALSE,quote = FALSE ,)
sum(final$solicit)
sum(out_sample$revenue)
sum(out_sample$predi_score)

