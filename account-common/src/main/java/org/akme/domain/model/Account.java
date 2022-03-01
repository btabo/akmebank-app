package org.akme.domain.model;

import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

public class Account {
    public static final String SAVINGS_ACCOUNT="Savings";
    public static final String CHEKING_ACCOUNT="Checking";
    public static final String CD_ACCOUNT="CD";

    private String id;
    private String type;
    private double availableBalance;
    private double presentBalance;
    private double interestRate;

    public Account() {
    }

    public Account(String id, String type, double availableBalance, double presentBalance, double interestRate) {
        super();
        this.id = id;
        this.type = type;
        this.availableBalance = availableBalance;
        this.presentBalance = presentBalance;
        this.interestRate = interestRate;
    }

    @Override
    public int hashCode() {
        return HashCodeBuilder.reflectionHashCode(this);
    }

    @Override
    public boolean equals(Object obj) {
        return EqualsBuilder.reflectionEquals(this, obj);
    }

    public static String getSavingsAccount() {
        return SAVINGS_ACCOUNT;
    }

    public static String getChekingAccount() {
        return CHEKING_ACCOUNT;
    }

    public static String getCdAccount() {
        return CD_ACCOUNT;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public double getAvailableBalance() {
        return availableBalance;
    }

    public void setAvailableBalance(double availableBalance) {
        this.availableBalance = availableBalance;
    }

    public double getPresentBalance() {
        return presentBalance;
    }

    public void setPresentBalance(double presentBalance) {
        this.presentBalance = presentBalance;
    }

    public double getInterestRate() {
        return this.interestRate;
    }

    public void setInterestRate(double interestRate) {
        this.interestRate = interestRate;
    }

}

