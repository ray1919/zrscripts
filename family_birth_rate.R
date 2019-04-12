
born <- function() {
  if (runif(1) > (1-105/205)) {
    return("M")
  } else {
    return("F")
  }
}

family_bady <- function() {
  baby <- born()
  while(baby[length(baby)] != "M") {
    baby <- c(baby, born())
  }
  return(baby)
}

all_babies <- c()

for (i in 1:10000) {
  all_babies <- c(all_babies, family_bady())
1}

table(all_babies)

