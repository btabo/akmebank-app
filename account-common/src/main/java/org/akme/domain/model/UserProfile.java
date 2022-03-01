package org.akme.domain.model;

import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

public class UserProfile{
    private String id;
    private String firstName;
    private String lastName;
    private Address address;
    private String phoneNumber;
    private String email;
    private String taxID;
    private String[] accountNumbers;

    public UserProfile() {
    }

    public UserProfile(String id, String firstName, String lastName, Address address, String phoneNumber, String email,
    String taxID, String[] accountNumbers) {
        super();
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.taxID = taxID;
        this.accountNumbers = accountNumbers;
    }

    @Override
    public int hashCode() {
        return HashCodeBuilder.reflectionHashCode(this);
    }

    @Override
    public boolean equals(final Object obj) {
        return EqualsBuilder.reflectionEquals(this, obj);
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(final String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(final String lastName) {
        this.lastName = lastName;
    }

    public Address getAddress() {
        return address;
    }

    public void setAddress(final Address address) {
        this.address = address;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(final String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(final String email) {
        this.email = email;
    }

    public String getTaxID() {
        return taxID;
    }

    public void setTaxID(final String taxID) {
        this.taxID = taxID;
    }

    public String[] getAccountNumbers() {
        return accountNumbers;
    }

    public void setAccountNumbers(final String[] accountNumbers) {
        this.accountNumbers = accountNumbers;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }


}